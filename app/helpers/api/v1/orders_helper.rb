module Api::V1::OrdersHelper
  require "uri"
  require "net/http"
  require "net/https"
  require "open-uri"
  require "json"
  require "crack" # for xml and json
  require "crack/json" # for just json
  require "crack/xml" # for just xml

  def order_json(order)
    order.as_json(include: [order_items: { only: [:id, :quantity, :description], include: [item_addons: { except: [:item_addon_category_id, :created_at, :updated_at] }] }]).merge(branch: order.branch.as_json)
  end

  def order_list_json(orders, language, area)
    unless orders.is_a?(Enumerable)
      orders.branch.restaurant.language = language
      orders.branch.area = area.present? ? area : (orders.user&.cart&.coverage_area_id || orders.coverage_area_id)
    else
      orders.each do |o|
        o.branch.restaurant.language = language
        o.branch.area = area.present? ? area : (o.user&.cart&.coverage_area_id || o.coverage_area_id)
      end
    end

    orders.as_json(language: language, include: [{ user: user_except_attributes }, { branch: { except: [:restaurant_id, :created_at, :updated_at, :talabat_id], methods: [:discount], include: [restaurant: { only: [:id, :title, :logo] }] } }, order_items: { only: [:id, :quantity, :description], include: [{ menu_item: { only: [:id, :item_name, :item_rating, :item_name_ar] } }, item_addons: { except: [:item_addon_category_id, :created_at, :updated_at] }] }])
    # orders.as_json(include: [:branch=>{include:[:restaurant=>{:except=>[:created_at,:updated_at]}]},:order_items=>{:only=>[:id,:quantity,:description],include:[:menu_item ,:item_addons=>{:except=>[:item_addon_category_id,:created_at,:updated_at]} ] } ])
  end

  def order_show_json(order, language)
    @area = order.user&.cart&.coverage_area_id || order.coverage_area_id
    order.as_json(language: language, include: [order_items: { only: [:id, :quantity, :description, :discount_amount, :total_item_price, :vat_price], methods: [:total_price_per_item, :price_per_item], include: [{ menu_item: { except: [:created_at, :updated_at, :menu_category_id] } }, item_addons: { except: [:created_at, :updated_at] }] }]).merge(branch: order.branch.as_json(language: language, areaWies: @area), user: order.user.as_json, transporter: order.transporter.as_json, rating: order.rating)
  end

  def order_status_json(order)
    order.as_json(only: [:id, :order_type, :payment_mode, :pickedup, :is_accepted, :is_delivered, :is_paid, :is_ready, :qr_image, :created_at, :delivered_at, :pickedup_at, :accepted_at, :cooked_at]).merge(transporter: order.transporter.as_json)
  end

  def order_transporter_json(order)
    order.as_json(only: [:id, :order_type, :payment_mode, :pickedup, :is_delivered, :is_paid, :is_ready, :qr_image, :pickedup_at]).merge(transporter: order.transporter.as_json)
  end

  def orders_branch_json(orders, language)
    orders.as_json(language: language, include: [{ user: user_except_attributes }, { order_items: { only: [:id, :quantity, :description], include: [{ menu_item: { only: [:id, :item_name, :item_rating] } }] } }])
  end

  def order_transporter_show_json(order)
    order.as_json(include: [order_items: { only: [:id, :quantity, :description], include: [{ menu_item: { except: [:created_at, :updated_at, :menu_category_id] } }, item_addons: { except: [:created_at, :updated_at] }] }]).merge(branch: order.branch.as_json, user: order.user.as_json)
    # order.as_json(include: [:order_items=>{:only=>[:id,:quantity,:description],include:[:menu_item=>{:except=>[:created_at,:updated_at,:menu_category_id]}] }]).merge(:branch=>order.branch.as_json,:user=>order.user.as_json)
  end

  def order_item_addons_except_attributes
    { except: [:created_at, :updated_at] }
  end

  def order_items_except_attributes
    { except: [:created_at, :updated_at, :image] }
  end

  def item_addons_except_attributes
    { except: [:created_at, :updated_at] }
  end

  def verify_payment(user, guestToken, transaction_id, address_id, _pt_transaction_id, _pt_token, _pt_token_customer_password, _pt_token_customer_email, order_mode, note, is_redeem, on_demand, dine_in_order)
    transactionDetails = transaction_id
    if (order_mode == "prepaid") || (order_mode == "postpaid") || (order_mode == "card_machine")
      address = Address.find_address(address_id)
      order = order_placed(user, guestToken, transactionDetails, address, order_mode, note, is_redeem, on_demand, dine_in_order)
    else
      false
    end

    rescue Exception => e
  end

  def order_placed(user, _guestToken, transactionDetails, address, order_mode, note, is_redeem, on_demand, dine_in_order)
    cart = user.present? ? user.cart : Cart.find_by(guest_token: @guestToken)
    user = user.presence || address&.user
    totalAmount = ["prepaid", "postpaid"].include?(order_mode) ? get_cart_item_total_price_checkout(cart, is_redeem, "", params[:address_latitude], params[:address_longitude], on_demand, dine_in_order) : get_cart_item_total_price_checkout(cart, is_redeem, "", params[:address_latitude], params[:address_longitude], on_demand, dine_in_order)
    Order.create_order(user, cart, transactionDetails, totalAmount, address, order_mode, note, to_boolean(is_redeem))
  end

  def get_transaction(transaction_id)
    Order.find_transaction(transaction_id)
  end

  def get_order_list(user, page, per_page)
    Order.find_order_list(user, page, per_page)
  end

  def find_order(order_id, user)
    Order.get_transporter_order(order_id, user)
  end

  def get_branch_order(order_id, branch_id)
    Order.find_business_orders(order_id, branch_id)
  end

  def get_business_order_list(branch, keyword, page, per_page)
    Order.find_business_orders_list(branch, keyword, page, per_page)
  end

  def update_order(order, action_for, cancel_resion)
    case action_for
    when "accept"
      result = order.update!(is_accepted: true, is_rejected: false, accepted_at: DateTime.now)

      unless order.dine_in
        update_fixed_fc_charge(order) if order.branch.fixed_charge_percentage.to_f.positive?
        update_branch_pending_amount(order)
        order_accept_worker(order.id)
      end
    when "reject"
      unless order.is_cancelled
        result = order.update(is_accepted: false, is_rejected: true, cancel_reason: cancel_resion)

        unless order.dine_in
          order_reject_worker(order.id)

          if order.total_amount.to_f.positive? && order.transection_id.present? && order.order_type == "prepaid"
            refund_amount_to_customer(order)
            order.branch.update(pending_amount: (order.branch.pending_amount - order.card_charge.to_f.round(3)))
          end

          Point.create_point(order, order.user.id, format("%0.03f", order.used_point), "Credit") if order.used_point.to_f.positive?

          if order.coupon_code.present?
            applied_coupon = InfluencerCoupon.find_by(coupon_code: order.coupon_code)
            referral_coupon = ReferralCoupon.find_by(coupon_code: order.coupon_code)
            restaurant_coupon = RestaurantCoupon.find_by(coupon_code: order.coupon_code)

            if applied_coupon.present?
              InfluencerCouponUser.find_by(influencer_coupon_id: applied_coupon.id, user_id: order.user&.id)&.destroy
              applied_coupon.update(quantity: (applied_coupon.quantity + 1))
            elsif restaurant_coupon.present?
              RestaurantCouponUser.find_by(restaurant_coupon_id: restaurant_coupon.id, user_id: order.user&.id)&.destroy
              restaurant_coupon.update(quantity: (restaurant_coupon.quantity + 1))
            elsif referral_coupon.present?
              referral_coupon_user = ReferralCouponUser.where(referral_coupon_id: referral_coupon.id, user_id: order.user&.id, available: false).first
              referral_coupon_user&.update(available: true)
              referral_coupon_user.referrer ? referral_coupon.update(referrer_quantity: (referral_coupon.referrer_quantity + 1)) : referral_coupon.update(referred_quantity: (referral_coupon.referred_quantity + 1))
            end
          end
        end
      end
    else
      result = false
    end
    result
  end

  def refund_amount_to_customer(order)
    url = URI("https://api.tap.company/v2/refunds")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
    request["content-type"] = "application/json"

    refund_data = {
      "charge_id": order.transection_id,
      "amount": order.total_amount,
      "currency": order.currency_code_en,
      "description": "Food Club Order Refund",
      "reason": "Food Club Order Refund"
    }

    request.body = refund_data.to_json
    response = http.request(request)
    @data = JSON.parse(response.read_body)
    order.update(refund_id: @data["id"]) if @data["id"].present?
  end

  def update_branch_pending_amount(order)
    amount = 0

    if order.order_type == "prepaid"
      if order.third_party_delivery
        bca = BranchCoverageArea.find_by(branch_id: order.branch_id, coverage_area_id: order.coverage_area_id)

        if bca&.third_party_delivery_type == "Chargeable"
          amount += order.sub_total.to_f - order.used_point.to_f + order.total_tax_amount.to_f
        else
          if order.branch.latitude.present? && order.branch.longitude.present? && order.latitude.present? && order.longitude.present?
            dist = Geocoder::Calculations.distance_between([order.branch.latitude, order.branch.longitude], [order.latitude, order.longitude], units: :km).to_f.round(3)
            delivery_charge = get_delivery_charge_by_distance(dist, order.branch.restaurant.country_id)
          else
            delivery_charge = 0.0
          end

          amount += order.sub_total.to_f - order.used_point.to_f + order.total_tax_amount.to_f - delivery_charge.to_f
        end

        fixed_fc_charge_percentage = DeliveryCharge.find_by(country_id: order.branch.restaurant.country_id)&.delivery_percentage
        fc_charge = ((order.sub_total * fixed_fc_charge_percentage / 100.to_f) * (100 + order.branch.total_tax_percentage) / 100.to_f)

        amount -= fc_charge
      else
        amount += order.total_amount.to_f.round(3)
      end

      if order.transection_id.present?
        url = URI("https://api.tap.company/v2/charges/#{order.transection_id}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(url)
        request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
        request.body = "{}"
        response = http.request(request)
        data = JSON.parse(response.read_body)

        if data["source"] && data["source"]["payment_type"] == "CREDIT"
          order.update(card_type: "Credit")
          card_charge = (order.total_amount.to_f * 2.2/100.to_f)
        elsif data["source"] && data["source"]["payment_type"] == "DEBIT"
          order.update(card_type: "Debit")
          card_charge = (order.total_amount.to_f * 1/100.to_f)
        else
          card_charge = 0
        end

        amount -= card_charge
      end
    end

    order.branch.update(pending_amount: (order.branch.pending_amount + amount.to_f.round(3)))
  end

  def deduct_branch_pending_amount(order)
    amount = 0

    if order.order_type == "prepaid"
      if order.third_party_delivery
        bca = BranchCoverageArea.find_by(branch_id: order.branch_id, coverage_area_id: order.coverage_area_id)

        if bca&.third_party_delivery_type == "Chargeable"
          amount += order.sub_total.to_f - order.used_point.to_f + order.total_tax_amount.to_f
        else
          if order.branch.latitude.present? && order.branch.longitude.present? && order.latitude.present? && order.longitude.present?
            dist = Geocoder::Calculations.distance_between([order.branch.latitude, order.branch.longitude], [order.latitude, order.longitude], units: :km).to_f.round(3)
            delivery_charge = get_delivery_charge_by_distance(dist, order.branch.restaurant.country_id)
          else
            delivery_charge = 0.0
          end

          amount += order.sub_total.to_f - order.used_point.to_f + order.total_tax_amount.to_f - delivery_charge.to_f
        end

        fixed_fc_charge_percentage = DeliveryCharge.find_by(country_id: order.branch.restaurant.country_id)&.delivery_percentage
        fc_charge = ((order.sub_total * fixed_fc_charge_percentage / 100.to_f) * (100 + order.branch.total_tax_percentage) / 100.to_f)

        amount -= fc_charge
      else
        amount += order.total_amount.to_f.round(3)
      end

      if order.transection_id.present?
        url = URI("https://api.tap.company/v2/charges/#{order.transection_id}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(url)
        request["authorization"] = "Bearer #{Rails.application.secrets['tap_secret_key']}"
        request.body = "{}"
        response = http.request(request)
        data = JSON.parse(response.read_body)

        if data["source"] && data["source"]["payment_type"] == "CREDIT"
          card_charge = (order.total_amount.to_f * 2.2/100.to_f)
        elsif data["source"] && data["source"]["payment_type"] == "DEBIT"
          card_charge = (order.total_amount * 1/100.to_f)
        else
          card_charge = 0
        end

        amount -= (card_charge * 2)
      end
    end

    order.branch.update(pending_amount: (order.branch.pending_amount - amount.to_f.round(3)))
  end

  def get_dine_in_transporter
    User.find_by(email: "dineintransporter@foodclube.com")
  end

  def find_transporter_order(order_id, user)
    Order.get_transporter_order(order_id, user)
  end

  def find_order_id(order_id)
    Order.find_by(id: order_id)
  end

  def add_order_transport(businessUser, order_id, user_id, amount)
    order = find_order_id(order_id)
    user = find_user(user_id)
    order_data = user && order ? get_user_auth(user, "transporter") ? order.update!(transporter_id: user.id) : nil : nil
    OrderDriver.create(order_id: order.id, transporter_id: user.id, driver_assigned_at: DateTime.now) if order.transporter
    ordertype = get_order_type(order_id)
    iouOrder = get_iou_order(order_id)

    amount = user.delivery_company_id.present? ? order.total_amount.to_f.round(3) : amount

    if amount.present? && ordertype.present? && !iouOrder && !order.dine_in
      Iou.create_iou(businessUser, order_id, user_id, amount)
    end

    order_data ? { status: true, order: order, user: user } : { status: false, order: "", user: "" }
  end

  def transporter_orders_by_status(status, user, page, per_page)
    case status
    when "completed"
      allHistory_transport_orders(user).paginate(page: page, per_page: per_page)
    when "today"
      today_transport_orders(user).paginate(page: page, per_page: per_page)
    else
      []
    end
  end

  def complete_transport_orders_count(user)
    Order.where("Date(delivered_at) = ? and transporter_id = ? and is_accepted = ? and is_ready = ? and pickedup = ? and is_delivered = ? and is_cancelled = ?", Date.current, user.id, true, true, true, true, false)
  end

  def today_transport_delivered_orders_count(user)
    Order.where("Date(updated_at) = ?  and transporter_id = ? and is_delivered = ? and is_cancelled = ?", Date.current, user.id, false, false)
  end

  def complete_transport_orders(user)
    Order.where("Date(delivered_at) = ? and transporter_id = ? and is_accepted = ? and is_ready = ? and pickedup = ? and is_delivered = ? and is_cancelled = ?", Date.current, user.id, true, true, true, true, false)
  end

  def today_transport_orders(user)
    Order.where("(Date(updated_at) = ? or DATE(delivered_at) = ?) and transporter_id = ? and (is_delivered = ? and is_settled = ?) and is_cancelled = ?", Date.current, Date.current, user.id, false, false, false).order(id: "DESC")
  end

  def allHistory_transport_orders(user)
    Order.where("transporter_id = ? and is_accepted = ? and is_ready = ? and pickedup = ? and is_delivered = ? and is_settled = ? and is_cancelled = ?", user.id, true, true, true, true, false, false).order(id: "DESC")
  end

  def update_order_delivered_status(order_id, user)
    order = find_transporter_order_status(order_id, user)
    status = order ? order.update(is_delivered: true, is_paid: (order.order_type == "postpaid" ? true : order.is_paid), delivered_at: DateTime.now, is_settled: (order.order_type == "prepaid" || order.dine_in), settled_at: (order.order_type == "prepaid" || order.dine_in) ? DateTime.now : "") : false
    point = add_point(order) if !order.on_demand && !order.dine_in
    EmailOnOrderDeliver.perform_async(order_id) if order && !order.dine_in
    { status: status, order: order }
  end

  def update_order_status(order_id, branch_id, role)
    order = Order.find_by(id: order_id, pickedup: true, branch_id: branch_id)

    if ((role == "business") || (role == "manager")) && (order.is_delivered == false)
      status = order ? order.update(is_delivered: true, is_paid: (order.order_type == "postpaid" ? true : order.is_paid), delivered_at: DateTime.current, is_settled: order.order_type == "prepaid" ? true : order.order_type != "postpaid", settled_at: order.order_type == "prepaid" ? DateTime.current : order.order_type == "postpaid" ? "" : DateTime.current) : false
      order.update(is_settled: true, settled_at: DateTime.now) if order && order.dine_in
      point = add_point(order) if !order.on_demand && !order.dine_in
      EmailOnOrderDeliver.perform_async(order_id) if order && !order.dine_in
      { status: status, order: order }
    else
      { status: false, order: order }
    end
  end

  def update_fixed_fc_charge(order)
    order_branch = order.branch
    fixed_fc_charge_percentage = order_branch.fixed_charge_percentage.to_f
    max_charge = order_branch.max_fixed_charge.to_f
    fc_charge = ((order.sub_total * fixed_fc_charge_percentage / 100.to_f) * (100 + order_branch.total_tax_percentage) / 100.to_f).to_f.round(3)
    current_month_charges = Order.where("branch_id = ? AND DATE(created_at) >= ?", order.branch_id, Date.today.beginning_of_month).sum(:fixed_fc_charge).to_f.round(3)
    fc_charge = (max_charge - current_month_charges).to_f.round(3) if max_charge.positive? && ((current_month_charges + fc_charge) > max_charge)
    order.update(fixed_fc_charge: fc_charge)
    order_branch.update(pending_amount: (order_branch.pending_amount - fc_charge))
  end

  def find_transporter_order_status(order_id, user)
    Order.get_transporter_order_status(order_id, user)
  end

  def update_items_status(order_items)
    items = OrderItem.find_items(order_items)
    item = items.present? ? items.update_all(is_delivered: true) : false
  end

  def get_order_type(order_id)
    Order.where("id = ? and order_type = (?)", order_id, "postpaid")
  end

  def get_iou_order(order_id)
    Iou.find_by(order_id: order_id)
  end

  def week_orders_data(branch_id)
    branch = get_branch(branch_id)
    if branch
      currency = branch.restaurant.country&.currency_code.to_s
      current = current_week_orders_data(branch_id)
      last_week = last_week_orders_data(branch_id)
      total_this_week = total_week_data(current)
      total_last_week = total_week_data(last_week)
      yesterday = calculate_day_orders(Date.today + 1, branch_id)
      today = calculate_day_orders(Date.today, branch_id)
      { status: true, result: { current: current, last_week: last_week, total_this_week: total_this_week, total_last_week: total_last_week, yesterday: yesterday, today: today, currency_code_en: currency, currency_code_ar: currency } }
    else
      { status: false }
    end
  end

  def calculate_day_orders(date, branch_id)
    Order.check_order_date(date, branch_id).sum(:total_amount).to_f.round(3)
  end

  def current_week_orders_data(branch_id)
    startdate = find_beginning_week
    calculate_week_data(startdate, branch_id)
  end

  def last_week_orders_data(branch_id)
    startdate = find_beginning_week - 1.week
    calculate_week_data(startdate, branch_id)
  end

  def calculate_week_data(startdate, branch_id)
    result = {}
    result[startdate.strftime("%A").to_s] = calculate_day_orders(startdate, branch_id)
    result[(startdate + 1).strftime("%A").to_s] = calculate_day_orders(startdate + 1, branch_id)
    result[(startdate + 2).strftime("%A").to_s] = calculate_day_orders(startdate + 2, branch_id)
    result[(startdate + 3).strftime("%A").to_s] = calculate_day_orders(startdate + 3, branch_id)
    result[(startdate + 4).strftime("%A").to_s] = calculate_day_orders(startdate + 4, branch_id)
    result[(startdate + 5).strftime("%A").to_s] = calculate_day_orders(startdate + 5, branch_id)
    result[(startdate + 6).strftime("%A").to_s] = calculate_day_orders(startdate + 6, branch_id)
    result
  end

  def total_week_data(hashValue)
    sum = 0
    p hashValue
    hashValue.values.map { |e| sum += e.to_f }
    sum.to_f.round(3)
  end

  def get_order_details(order_id)
    Order.find_order_details(order_id)
  end

  def update_order_stage(order)
    order.update(is_ready: true, cooked_at: (order.pickedup_at || DateTime.now))
    order.update(pickedup: true, pickedup_at: DateTime.now) if order.dine_in
  end

  def web_update_order_stage(order)
    order.update(cooked_at: DateTime.now, driver_assigned_at: DateTime.now)
    OrderDriver.where(order_id: order.id).last.update(driver_assigned_at: DateTime.now) if order.driver_assigned_at
    OrderAcceptNotificationWorker.perform_at(1.minutes.from_now, order.id)
    OrderCookingNotificationWorker.perform_at(20.minutes.from_now, order.id, "20")
    OrderCookingNotificationWorker.perform_at(30.minutes.from_now, order.id, "30")
    OrderCookingNotificationWorker.perform_at(40.minutes.from_now, order.id, "40")
  end

  def clear_cart_deta(cart)
    if cart.present?
      cart.cart_items.destroy_all
      cart.update(branch_id: nil)
    end
  end

  def add_iou_in_order(amount, businessUser, order_id, user_id)
    if amount.present?
      Iou.create_iou(businessUser, order_id, user_id, amount)
    end
  end

  def orderCookingPusherNotification(_user, order)
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    restaurant = order.branch.restaurant
    channelName = "public-restaurant" + restaurant.user.id.to_s # for restaurant owner
    pusher_client.trigger(channelName, "my-event",
                          root: channelName,
                          restaurant: restaurant,
                          data: "test",
                          restaurant_id: encode_token(restaurant.id))
  rescue StandardError
  end

  def orderPusherNotification(_user, order)
    @webPusher = web_pusher(Rails.env)
    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )
    channelName = "public-branch" + order.branch_id.to_s # for branch managers
    pusher_client.trigger(channelName, "my-event",
                          root: channelName)

    channelName = "public-branch-kitchen-managers" + order.branch_id.to_s # for kitchen managers
    pusher_client.trigger(channelName, "my-event",
                          root: channelName)
    restaurant = order.branch.restaurant
    channelName = "public-restaurant" + restaurant.user.id.to_s # for restaurant owner
    pusher_client.trigger(channelName, "my-event",
                          root: channelName,
                          restaurant: restaurant,
                          data: "test",
                          restaurant_id: encode_token(restaurant.id))
  rescue StandardError
  end

  def order_kitchen_pusher(order)
    @webPusher = web_pusher(Rails.env)
    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )
    channelName = "public-branch-kitchen-managers" + order.branch_id.to_s # for branch managers
    pusher_client.trigger(channelName, "my-event",
                          root: channelName)
  rescue StandardError
  end

  def get_user_last_order(user)
    user.orders.last
  end
end
