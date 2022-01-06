module Api::V1::PointsHelper
  def point_list_json(points)
    points.as_json(include: [branch: { only: [:id, :address], methods: [:restaurant_name, :restaurant_logo] }])
  end

  def add_point(order)
    if order.coupon_code.present?
      if order.coupon_type == "influencer"
        coupon_user_id = InfluencerCoupon.find_by(coupon_code: order.coupon_code)&.user_id
        point = (order.total_amount.to_f * 5) / 100
        Point.create_point(order, coupon_user_id, format("%0.03f", point), "Credit")
      elsif order.coupon_type == "restaurant"
        referral = Referral.find_by(email: order.user.email)
        refrral_point = point_percentage(order, "referral") if referral.present?
        Point.create_point(order, referral.user.id, format("%0.03f", refrral_point), "Credit") if referral.present? && order.order_items.pluck(:discount_amount).all?(&:zero?)
      end
    else
      point_type = "Credit"
      referral = Referral.find_by(email: order.user.email)
      refrral_point = point_percentage(order, "referral") if referral.present?
      Point.create_point(order, referral.user.id, format("%0.03f", refrral_point), point_type) if referral.present? && order.order_items.pluck(:discount_amount).all?(&:zero?)
      point = point_percentage(order, "non_referral")
      Point.create_point(order, order.user.id, format("%0.03f", point), point_type) if order.order_items.pluck(:discount_amount).all?(&:zero?)
    end
  rescue Exception => e
  end

  def point_percentage(order, type)
    pointPercentage = type == "non_referral" ? Servicefee.pluck(:direct_point_percentage).first : Servicefee.pluck(:refferal_point_percentage).first
    point = (order.total_amount.to_f * pointPercentage) / 100
  end

  def get_user_point(user, page, per_page, language)
    Point.find_user_point(user, page, per_page, language)
  end

  def get_user_point_list(user, page, per_page)
    Point.find_user_point_list(user, page, per_page)
  end

  def get_branch_wise_point(branch_id, user, page, per_page)
    Point.find_branch_wise_point(branch_id, user, page, per_page)
  end

  def get_influencer_selling_points(user, restaurant)
    all_points = Point.influencer_selling_points(user.id, restaurant.id).includes(:user, :order, :branch)
    point_ids = []
    sum = 0

    all_points.each do |p|
      if p.point_type == "Credit"
        sum += p.user_point

        if sum > 50
          diff = 50 - (sum - p.user_point)
          p.update(party_point: diff.to_f.round(3))
          point_ids << p.id
          break
        else
          p.update(party_point: p.user_point)
          point_ids << p.id
        end
      else
        # sum -= p.user_point
      end
    end

    Point.where(id: point_ids)
  end

  def sell_influencer_points(buyer, points, price, transaction_id)
    points.each do |point|
      Point.create(branch_id: point.branch_id, user_point: point.party_point, expired_date: point.expired_date, user_id: point.user_id, point_type: "Debit", transaction_id: transaction_id)
      Point.create(branch_id: point.branch_id, user_point: point.party_point, expired_date: point.expired_date, user_id: buyer.id, point_type: "Credit", transaction_id: transaction_id)
    end

    PartyPointWorker.perform_async(points.first&.user_id, points.first&.branch&.restaurant_id)
    update_user_pending_amount(points.first&.user, price, transaction_id)
  end

  def update_user_pending_amount(user, price, transaction_id)
    amount = price.to_f.round(3)

    if user && transaction_id.present? && amount.positive?
      url = URI("https://api.tap.company/v2/charges/#{transaction_id}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url)
      request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
      request.body = "{}"
      response = http.request(request)
      data = JSON.parse(response.read_body)

      if data["source"] && data["source"]["payment_type"] == "CREDIT"
        card_charge = (amount * 2.2/100.to_f)
      elsif data["source"] && data["source"]["payment_type"] == "DEBIT"
        card_charge = (amount * 1/100.to_f)
      else
        card_charge = 0
      end

      amount -= card_charge
      user.update(pending_amount: (user.pending_amount + amount.to_f.round(3)))
    end
  end

  def get_branch_wise_total_point(point)
    total = point.where(point_type: "Credit").sum(:user_point) - point.where(point_type: "Debit").sum(:user_point)
    helpers.number_with_precision(total, precision: 3)
  end

  def branch_available_point(user_id, branch_id)
    redeemPoint = Point.where(user_id: user_id, branch_id: branch_id).debited
    point = Point.where(user_id: user_id, branch_id: branch_id).credited
    point = Point.where(id: point.reject { |p| p.expired_date && p.expired_date.to_date < Date.today }.map(&:id))
    userPoint = point.pluck(:user_point).sum - redeemPoint.pluck(:user_point).sum
  end
end