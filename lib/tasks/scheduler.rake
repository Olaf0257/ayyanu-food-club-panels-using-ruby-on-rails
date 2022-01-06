desc "This task is called by the AWS CRON scheduler"
require "uri"
require "net/http"
require "#{Rails.root}/app/helpers/notifications_helper"
include NotificationsHelper

task influencer_contract_expiry: :environment do
  InfluencerContract.where("date(end_date) = ?", (Date.today + 1)).each do |contract|
    UserMailer.contract_expiry_email(contract.user.email, contract.user.name, contract.end_date).deliver_now
  end
end

task influencer_user_point_expiry: :environment do
  expiry_date = Date.today + 2

  User.where(influencer: true).each do |user|
    points = user.points.credited.select { |p| p.expired_date.to_date == expiry_date }
    UserMailer.user_point_expiry_email(user, points, expiry_date).deliver_now if points.present?
  end
end

task mail_top_five_restaurant_bidders: :environment do
  AddRequest.where(place: "list").each do |request|
    if AddRequest.where(place: "list", position: request.position, week_id: request.week_id, coverage_area_id: request.coverage_area_id).where("amount > ? OR (amount = ? AND id < ?)", request.amount, request.amount, request.id).present? && ((request.week.start_date == Date.today + 1.day) || (request.week.start_date == Date.today + 2.days))
      OfferMailer.add_request_notification_mail(request.id).deliver_now
    end
  end
end

task accept_top_five_restaurant_bidders: :environment do
  AddRequest.where(place: "list").each do |request|
    if request.week.start_date == Date.today
      if AddRequest.where(place: "list", position: request.position, week_id: request.week_id, coverage_area_id: request.coverage_area_id).where("amount > ? OR (amount = ? AND id < ?)", request.amount, request.amount, request.id).empty?
        Advertisement.create_advertisement(request.branch.restaurant_id, request.place, request.position, request.title, request.description, request.amount, request.week.start_date, request.week.end_date, request.id, request.branch_id, request.image)
        charge = request.amount.to_f * (100 + request.branch.total_tax_percentage) / 100.to_f
        request.branch.update(pending_amount: (request.branch.pending_amount - charge.to_f.round(3)))
        request.update(is_accepted: true)
        BranchCoverageArea.find_by(branch_id: request.branch_id, coverage_area_id: request.coverage_area_id)&.update(position: request.position)
        OfferMailer.advertisement_approval_mail(request.id).deliver_now
      else
        request.update(is_reject: true)
      end
    end
  end
end

task remove_branch_coverage_area_rankings: :environment do
  Advertisement.where("date(from_date) > ? OR date(to_date) < ?", Date.today, Date.today).each do |ad|
    request = ad.add_request
    BranchCoverageArea.find_by(branch_id: request.branch_id, coverage_area_id: request.coverage_area_id)&.update(position: 100)
  end
end

task charge_branch_subscription_fees: :environment do
  if Date.today.day == 1
    Branch.joins(:restaurant).where(is_approved: true, fixed_charge_percentage: nil, restaurants: { is_signed: true }).uniq.each do |branch|
      branch_fee = (branch.branch_subscription&.fee.to_f * (100 + branch.total_tax_percentage) / 100.to_f).to_f.round(3)
      report_fee = (branch.report_subscription&.fee.to_f * (100 + branch.total_tax_percentage) / 100.to_f).to_f.round(3)
      total_fee = branch_fee + report_fee
      branch.update(pending_amount: (branch.pending_amount - total_fee))
    end
  end
end

task transfer_amounts_to_branches: :environment do
  BranchBankDetail.where.not(destination_id: [nil, "", "NA"]).each do |branch_bank_detail|
    all_branches = branch_bank_detail.branch.restaurant.branches

    if all_branches.select { |b| b.branch_bank_detail.present? }.count == 1
      branches = all_branches
    else
      branches = Branch.where(id: branch_bank_detail.branch_id)
    end

    branches.each do |branch|
      if branch.is_approved && branch.restaurant.is_signed
        pending_amount = branch.pending_amount.to_f.round(3)

        next unless pending_amount.positive?
        url = URI("https://api.tap.company/v2/transfers")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(url)
        request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
        request["content-type"] = "application/json"

        payment_data = {
          "currency": branch.currency_code_en,
          "amount": pending_amount,
          "source": Rails.application.secrets["tap_merchant_id"],
          "destination": branch_bank_detail.destination_id,
          "description": "Food Club Settlement"
        }

        request.body = payment_data.to_json
        response = http.request(request)
        data = JSON.parse(response.read_body)

        if data["id"].present?
          branch.branch_payments.create(amount: pending_amount, transaction_id: data["id"])
          branch.update(pending_amount: (branch.pending_amount - pending_amount))
        end
      end
    end
  end
end

task transfer_amounts_to_influencers: :environment do
  InfluencerBankDetail.where.not(destination_id: [nil, "", "NA"]).each do |influencer_bank_detail|
    user = influencer_bank_detail.user

    if user.is_approved == 1
      pending_amount = user.pending_amount.to_f.round(3)

      next unless pending_amount.positive?
      url = URI("https://api.tap.company/v2/transfers")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(url)
      request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
      request["content-type"] = "application/json"

      payment_data = {
        "currency": user.country.currency_code,
        "amount": pending_amount,
        "source": Rails.application.secrets["tap_merchant_id"],
        "destination": influencer_bank_detail.destination_id,
        "description": "Food Club Settlement"
      }

      request.body = payment_data.to_json
      response = http.request(request)
      data = JSON.parse(response.read_body)

      if data["id"].present?
        user.influencer_payments.create(amount: pending_amount, transaction_id: data["id"])
        user.update(pending_amount: (user.pending_amount - pending_amount))
      end
    end
  end
end

task send_user_cart_details_mail: :environment do
  Cart.joins(:cart_items).where.not(user_id: nil, branch_id: nil).distinct.each do |cart|
    if Time.zone.now.hour == 12 && cart.user && cart.updated_at.to_date == (Time.zone.now.to_date - 1)
      fire_single_notification("Food Club", "You have Items in your Cart. Go Ahead and Order.", nil, cart.user.email)
      UserMailer.cart_details_mail(cart.id).deliver_now
    end
  end
end

task send_event_reminder_mail: :environment do
  EventDate.all.each do |event_date|
    if event_date.start_date == (Date.today + 14.days)
      event = event_date.event
      country_ids = event.event_countries.pluck(:country_id).uniq

      country_ids.each do |country_id|
        restaurants = Restaurant.joins(:branches).where(country_id: country_id, is_signed: true, branches: { is_approved: true }).distinct

        restaurants.each do |restaurant|
          RestaurantMailer.event_reminder_mail(restaurant.id, event_date.id).deliver_now if restaurant.user
        end
      end

      RestaurantMailer.event_reminder_mail(nil, event_date.id).deliver_now
    end
  end
end

task send_order_summary_mail: :environment do
  if Date.today.day == 1
    branches = Branch.joins(:restaurant).where(is_approved: true, restaurants: { is_signed: true }).distinct.order("restaurants.title")

    branches.each do |branch|
      all_orders = Order.where("DATE(orders.created_at) >= ? AND DATE(orders.created_at) <= ?", Date.yesterday.beginning_of_month, Date.yesterday.end_of_month).where(dine_in: false, branch_id: branch.id)
      delivered_orders = all_orders.where(is_delivered: true)
      refund_orders = all_orders.where(refund: true)

      if branch.restaurant.user
        RestaurantMailer.order_summary_report_mail(branch.id, delivered_orders.pluck(:id), refund_orders.pluck(:id)).deliver_now
        RestaurantMailer.tax_invoice_mail(branch.id, delivered_orders.pluck(:id)).deliver_now
      end
    end
  end
end
