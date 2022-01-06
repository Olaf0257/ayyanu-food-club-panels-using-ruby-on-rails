class Customer::OrdersController < ApplicationController
  before_action :authenticate_customer
  before_action :validate_order, only: [:place_order]

  def place_order
    @user = User.find(params[:user_id])
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    @area = cart&.coverage_area_id
    carItem = cart&.cart_items

    if carItem.present?
      verifyPayment = verify_payment(@user, @guestToken, params[:transaction_id], params[:address_id], params[:pt_transaction_id], params[:pt_token], params[:pt_token_customer_password], params[:pt_token_customer_email], params[:order_mode], params[:note], params[:is_redeem], false, false)

      if verifyPayment
        clearCart = clear_cart_deta(cart)

        if params[:coupon_code].present?
          influencer_coupon = InfluencerCoupon.find_by(coupon_code: params[:coupon_code])
          referral_coupon = ReferralCoupon.find_by(coupon_code: params[:coupon_code])
          restaurant_coupon = RestaurantCoupon.find_by(coupon_code: params[:coupon_code])

          if influencer_coupon && @user
            InfluencerCouponUser.create(influencer_coupon_id: influencer_coupon.id, user_id: @user.id)
            influencer_coupon.update(quantity: (influencer_coupon.quantity - 1))
            influencer_coupon.update(active: false) if influencer_coupon.quantity.zero?
            verifyPayment.update(coupon_type: "influencer", coupon_code: influencer_coupon.coupon_code)
          elsif restaurant_coupon && @user
            RestaurantCouponUser.create(restaurant_coupon_id: restaurant_coupon.id, user_id: @user.id)
            restaurant_coupon.update(quantity: (restaurant_coupon.quantity - 1))
            restaurant_coupon.update(active: false) if restaurant_coupon.quantity.zero?
            verifyPayment.update(coupon_type: "restaurant", coupon_code: restaurant_coupon.coupon_code)
          elsif referral_coupon && @user
            referral_coupon_user = ReferralCouponUser.where(referral_coupon_id: referral_coupon.id, user_id: @user.id, available: true).first

            if referral_coupon_user
              available = referral_coupon_user.referrer ? referral_coupon.referrer_quantity.positive? : referral_coupon.referred_quantity.positive?

              if available
                if referral_coupon_user.referrer
                  referral_coupon.update(referrer_quantity: (referral_coupon.referrer_quantity - 1))
                else
                  referral_coupon.update(referred_quantity: (referral_coupon.referred_quantity - 1))
                end

                referral_coupon_user.update(available: false)
                verifyPayment.update(coupon_type: "referral", coupon_code: referral_coupon.coupon_code)
              end
            end
          end
        end

        if @user
          orderPushNotificationWorker(@user, verifyPayment.branch.restaurant.user, "order_created", "Order Created", "Order Id #{verifyPayment.id} is placed by user #{@user.name}", verifyPayment.id)
          orderPusherNotification(@user, verifyPayment)
          send_notification_releted_menu("Order Id #{verifyPayment.id} is placed by user #{@user.name}", "order_created", @user, get_admin_user, verifyPayment.branch.restaurant_id)
          responce_json(code: 200, message: "Order placed successfully.", order: order_list_json(verifyPayment, request.headers["language"], @area))
        else
          begin
            noti = Notification.create(notification_type: "order_created", message: "Order Id #{verifyPayment.id} is placed by user #{verifyPayment.user.name}", user_id: verifyPayment.user.id, receiver_id: verifyPayment.branch.restaurant.user.id, order_id: verifyPayment.id)
            orderPusherNotification("", verifyPayment)
          rescue Exception => e
          end
          responce_json(code: 200, message: "Order placed successfully.", order: order_list_json(verifyPayment, request.headers["language"], @area))
        end
      else
        responce_json(code: 422, message: "Invalid transaction!!")
      end
    else
      responce_json(code: 422, message: "Cart empty!!")
    end

    rescue Exception => e
  end

  def place_dine_in_order
    @user = User.find_by(id: params[:user_id])
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    @area = cart&.coverage_area_id
    carItem = cart&.cart_items

    if carItem.present?
      new_user = User.create(name: (params[:order_type] == "dine_in" ? "Dine In User" : "Takeaway User"), email: (@guestToken + "@foodclube.com"))
      new_address = new_user.addresses.find_or_create_by(address_name: "Dine In", coverage_area_id: cart.coverage_area_id)
      verifyPayment = verify_payment(@user, @guestToken, nil, new_address.id, nil, nil, nil, nil, params[:order_mode], "", false, false, true)

      if verifyPayment
        clearCart = clear_cart_deta(cart)
        verifyPayment.update(third_party_delivery: false, dine_in: true, table_number: (params[:order_type] == "dine_in" ? params[:table_number].to_s.squish : nil))
        @user ||= verifyPayment.user
        orderPushNotificationWorker(@user, verifyPayment.branch.restaurant.user, "order_created", "Order Created", "Order Id #{verifyPayment.id} is placed by user #{@user.name}", verifyPayment.id)
        orderPusherNotification(@user, verifyPayment)
        send_notification_releted_menu("Order Id #{verifyPayment.id} is placed by user #{@user.name}", "order_created", @user, get_admin_user, verifyPayment.branch.restaurant_id)
        responce_json(code: 200, message: "Order placed successfully.", order: order_list_json(verifyPayment, request.headers["language"], @area))
      else
        responce_json(code: 422, message: "Invalid transaction!!")
      end
    else
      responce_json(code: 422, message: "Cart empty!!")
    end

    rescue Exception => e
  end

  def order_item_details
    @item = MenuItem.find(params[:item_id])
    @branch_id = @item.menu_category.branch_id
    @area_id = decode_token(params[:area_id])
    @addons = get_addon_item_list(@item, @user, nil)
    @price = @item.effective_price(@item.menu_category.branch_id)
  end

  def add_order_item
    @checkout = params[:checkout].presence

    if @checkout
      @cart_item = CartItem.find(params[:item_id])
      old_price = @cart_item.total_price
      @cart_item.update(quantity: (@cart_item.quantity.to_i + 1))
      @item = @cart_item.menu_item

      if @cart_item.cart_item_addons.present?
        @price = @cart_item.total_price.to_f - old_price.to_f
      else
        @price = @item.effective_price(@item.menu_category.branch_id)
      end
    else
      @item = MenuItem.find(params[:item_id])
      @price = @item.effective_price(@item.menu_category.branch_id)
    end
  end

  def deduct_order_item
    @checkout = params[:checkout].presence

    if @checkout
      @cart_item = CartItem.find(params[:item_id])
      old_price = @cart_item.total_price
      @cart_item.update(quantity: (@cart_item.quantity.to_i - 1))
      @item = @cart_item.menu_item

      if @cart_item.cart_item_addons.present?
        @price = old_price.to_f - @cart_item.total_price.to_f
      else
        @price = @item.effective_price(@item.menu_category.branch_id)
      end
    else
      @item = MenuItem.find(params[:item_id])
      @price = @item.effective_price(@item.menu_category.branch_id)
    end
  end

  def add_addon_item
    @menu_item =  MenuItem.find(params[:menu_item_id])
    @addon_item = ItemAddon.find(params[:item_id])
    @price = @addon_item.effective_price(@menu_item.offer_percent(@menu_item.menu_category.branch_id))
    @menu_item_price = @menu_item.effective_price(@menu_item.menu_category.branch_id)
  end

  def deduct_addon_item
    @menu_item =  MenuItem.find(params[:menu_item_id])
    @addon_item = ItemAddon.find(params[:item_id])
    @price = @addon_item.effective_price(@menu_item.offer_percent(@menu_item.menu_category.branch_id))
    @menu_item_price = @menu_item.effective_price(@menu_item.menu_category.branch_id)
  end

  def add_items_to_cart
    user = User.find_by(id: params[:user_id])
    @item = add_user_cart(user, @guestToken, params[:branch_id], params[:item_id], params[:item_addons].to_s.split(","), params[:quantity], params[:description], params[:area_id])
    cart = user ? user.reload.cart&.reload : Cart.find_by(guest_token: @guestToken)&.reload
    @cart_data = cart_list_json(get_cart_item_list(cart, request.headers["language"]))
  end

  def cart_item_list
    if params[:user_id].present? && params[:guest_token].blank?
      user = User.find_by(id: params[:user_id])
      auth = user&.auths&.find_by(role: "customer")
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:customer_user_id] = server_session.server_token
    end

    @call_center_user = session[:role_user_id].present?
    @my_points = params[:my_points] == "true"
    @user = current_user || User.find_by(email: @guestToken.to_s + "@foodclube.com")
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    bca = BranchCoverageArea.find_by(coverage_area_id: cart&.coverage_area_id, branch_id: cart&.branch_id)
    @coverage_area = cart&.coverage_area

    if bca
      if bca.is_closed
        flash[:error] = "Order cannot be placed as Restaurant is closed now"
        redirect_to request.referer
        return
      elsif bca.is_busy
        flash[:error] = "Order cannot be placed as Restaurant is busy now"
        redirect_to request.referer
        return
      end
    end

    if cart
      if @user
        @addresses = @user.addresses.where(coverage_area_id: cart.coverage_area_id)
        @selected_address = params[:address_id].present? ? Address.find(params[:address_id]) : @addresses.last
        @user_points = totalPoint = cart.branch_id.present? ? branch_available_point(cart.user.id, cart.branch.id) : 0.000
      end

      @cart_data = cart_list_json(get_cart_item_list(cart&.reload, request.headers["language"]))
      @total_price = get_cart_item_total_price_checkout(cart, @my_points.present?, nil, @selected_address&.latitude, @selected_address&.longitude, false, false)
    end
  end

  def remove_cart_item
    @user = current_user
    item = CartItem.find(params[:item_id])
    item.destroy
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    cart.update(branch_id: nil, coverage_area_id: nil) if cart.cart_items.count == 0
  end

  def live_order_tracking
    @order = find_order_id(params[:id])
    @driver = @order.transporter
    @branch = @order.branch
    render layout: "blank"
  end

  def mail_order_payment_link
    @user_id = params[:user_id]
    @redeem = params[:is_redeem]
    @address_id = params[:address_id]
    @note = params[:note]
    EmailOrderPaymentLinkWorker.perform_async(@user_id, @redeem, @address_id, @note)
    render json: { code: 200 }
  end

  def reorder_items
    order = Order.find_by(id: params[:order_id])

    if order
      available_items = order.order_items.available_menu_items

      if available_items.empty?
        responce_json(code: 422, message: "Sorry, no item in this order is available now.")
      elsif available_items.size != order.order_items.size
        responce_json(code: 422, message: "Sorry, some items in this order are not available now.")
      elsif order.branch.is_approved == false || order.branch.restaurant.is_signed == false
        responce_json(code: 422, message: "Sorry, Restaurant is closed now.")
      else
        cart = @user.cart
        clear_cart_deta(cart)

        order.order_items.each do |item|
          add_user_cart(@user, @guestToken, order.branch_id, item.menu_item_id, item.item_addons.pluck(:id), item.quantity, item.description, (order.coverage_area_id || cart&.coverage_area_id))
        end

        responce_json(code: 200, message: "Items successfully added.")
      end
    else
      responce_json(code: 422, message: "Order not found.")
    end
  end

  private

  def validate_order
    transaction = get_transaction(params[:transaction_id])
    cart = @user.present? ? @user.cart : Cart.find_by(guest_token: @guestToken)
    orderMode = params[:order_mode] == "postpaid" ? get_restaurant_branch(cart&.branch_id) : nil

    if ((params[:order_mode] == "prepaid") && transaction) || ((params[:order_mode] == "postpaid") && (orderMode&.cash_on_delivery == false))
      responce_json(code: 422, message: (transaction ? "Invalid transaction!!" : "This restaurant is currently not accepting cash on delivery(COD).").to_s)
    end

    rescue Exception => e
  end
end
