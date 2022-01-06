class Api::V1::OrdersController < Api::ApiController
  before_action :authenticate_guest_access
  before_action :validate_order, only: [:new_order]
  before_action :validate_branch, only: [:business_orders]
  before_action :validate_user_branch, only: [:branch_order_view, :orders_graph]
  before_action :validate_order_delivered, only: [:order_delivered]
  before_action :validate_order_checklist, only: [:check_items_list]

  def new_order
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    @area = cart&.coverage_area_id
    carItem = cart&.cart_items

    if carItem.present?
      verifyPayment = verify_payment(@user, @guestToken, params[:transaction_id], params[:address_id], params[:pt_transaction_id], params[:pt_token], params[:pt_token_customer_password], params[:pt_token_customer_email], params[:order_mode], params[:note], params[:is_redeem], false, false)
      # verifyPayment ? cart.cart_items.destroy_all : verifyPayment
      # p "========================verifyPayment============================"
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

  def reorder
    order = Order.get_order(params[:order_id], @user)

    if order
      available_items = order.order_items.available_menu_items

      if available_items.empty?
        responce_json(code: 422, message: "Sorry, no item in this order is available now.")
      elsif available_items.size != order.order_items.size
        responce_json(code: 422, message: "Sorry, some items in this order are not available now.")
      elsif order.branch.is_approved == false || order.branch.restaurant.is_signed == false
        responce_json(code: 422, message: "Sorry, Restaurant is closed now.")
      else
        cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
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

  def order_list
    orders = get_order_list(@user, params[:page], params[:per_page])
    responce_json(code: 200, message: "Order list.", orders: order_list_json(orders, request.headers["language"], @area), order_count: orders.count, total_pages: orders.total_pages)
  end

  def show_order
    order = Order.get_order(params[:order_id], @user)
    order ? responce_json(code: 200, message: "Order", orders: order_show_json(order, request.headers["language"])) : responce_json(code: 422, message: "Invalid Order")
  end

  def order_status
    order = find_order_id(params[:order_id])
    order ? responce_json(code: 200, message: "Order", orders: order_status_json(order)) : responce_json(code: 422, message: "Invalid Order")
  end

  def transporter_order
    order = find_order(params[:order_id], @user)
    order ? responce_json(code: 200, message: "Order", orders: order_transporter_json(order)) : responce_json(code: 422, message: "Invalid Order")
  end

  # business apis
  def business_orders
    orders = get_business_order_list(@branch, params[:keyword], params[:page], params[:per_page])
    responce_json(code: 200, message: "Order list.", orders: order_list_json(orders, "", ""))
  end

  def order_action
    order = Order.joins(branch: :restaurant).where("restaurants.user_id=? and orders.id=?", @user.id, params[:order_id]).first
    if order
      if !order.is_accepted && !order.is_rejected && !order.is_cancelled
        status = update_order(order, params[:action_for])
        if status
          orderPushNotificationWorker(@user, order.user, "order_#{params[:action_for]}", "Order #{order.is_accepted ? 'Accepted' : 'Rejected'}", "Order Id #{order.id} is #{order.is_accepted ? 'Accepted' : 'Rejected'}", order.id)
          responce_json(code: 200, message: "Order #{order.is_accepted ? 'Accepted' : 'Rejected'}", order: order_list_json(order, "", ""))
        else
          responce_json(code: 404, message: "Action #{params[:action_for]} does not exists")
        end
      else
        responce_json(code: 422, message: "Already #{order.is_cancelled ? 'Cancelled' : order.is_accepted ? 'Accepted' : 'Rejected'}")
       end
    else
      responce_json(code: 404, message: "Order does not exists")
     end
  end

  def branch_order_view
    order = get_branch_order(params[:order_id], params[:branch_id])
    order ? responce_json(code: 200, message: "Order", order: order_show_json(order, "")) : responce_json(code: 422, message: "Invalid Order")
  end

  def orders_graph
    orders = week_orders_data(params[:branch_id])
    orders[:status] ? send_json_response("Order Graph Data", "success", result: orders[:result]) : send_json_response("Invalid branch", "invalid", {})
  end

  # trandsporter apis
  def transporters_orders_list
    orders = transporter_orders_by_status(params[:status], @user, params[:page], params[:per_page])
    orders ? responce_json(code: 200, message: "Orders", completed_counts: complete_transport_orders_count(@user).count, today_counts: today_transport_delivered_orders_count(@user).count, orders: orders_branch_json(orders, request.headers["language"])) : responce_json(code: 422, message: "Invalid Order")
  end

  def transporter_order_show
    order = find_transporter_order(params[:order_id], @user)
    order ? responce_json(code: 200, message: "Order", order: order_transporter_show_json(order)) : responce_json(code: 422, message: "Invalid Order")
  end

  def add_transporter_to_order
    order = add_order_transport(@user, params[:order_id], params[:user_id], params[:amount])
    if order[:status]
      orderPushNotificationWorker(@user, order[:user], "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
      firebase = firebase_connection
      group = create_track_group(firebase, params[:user_id], "26.2285".to_f, "50.5860".to_f)
      responce_json(code: 200, message: "Order", order: order_transporter_json(order[:order]))
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  def update_transporter_in_order
    order = find_order_id(params[:order_id])
    if order && (order.transporter_id != params[:transporter_id].to_i) && (order.pickedup == false)
      order.iou.destroy if order.iou.present?
      firebase = firebase_connection
      group = update_track_order(firebase, order)
      orderPushNotificationWorker(@user, order.transporter, "transporter_remove", "Transporter Removed", "Transporter is removed to Order Id #{params[:order_id]}", params[:order_id])
      order.update(transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now, driver_accepted_at: nil)
      OrderDriver.create(order_id: order.id, transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now)
      OrderAcceptNotificationWorker.perform_at(1.minutes.from_now, order.id)
      add_iou_in_order(params[:amount], @user, order.id, params[:transporter_id]) if order.order_type == "postpaid"
      group = create_track_group(firebase, params[:transporter_id], "26.2285".to_f, "50.5860".to_f)
      responce_json(code: 200, message: "Order", order: order_transporter_json(order))
    else
      responce_json(code: 422, message: "Invalid request!!")
    end
  end

  def change_order_stage_onway
    order = find_order_id(params[:order_id])
    if order
      if order.is_ready == true
        order.update(pickedup: true, pickedup_at: DateTime.now)
        responce_json(code: 200, message: "Order On the way", order: order_show_json(order, ""))
      else
        responce_json(code: 422, message: "Order not cooked!!")
      end
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  # use firebase tracking
  def order_delivered
    order = (@userRole.first.role == "business") || (@userRole.first.role == "manager") ? update_order_status(params[:order_id], params[:branch_id], @user.auths.first.role) : update_order_delivered_status(params[:order_id], @user)
    firebase = firebase_connection
    # order[:status] ? delete_driver_from_groups(firebase,order[:order].transporter_id,order[:order].id) : ""
    if order[:status]
      # delete_driver_from_groups(firebase,order[:order].transporter_id,order[:order].id)
      orderPushNotificationWorker(@user, order[:order].user, "order_delivered", "Order Delivered", "Order Id #{order[:order].id} is delivered", order[:order].id)
      create_track_group(firebase, order[:order].transporter_id, "26.2285".to_f, "50.5860".to_f)
      order[:order].transporter.update(busy: false)
      responce_json(code: 200, message: "Order", order: order_status_json(order[:order]))
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  def order_update_cooked_stage
    order = get_branch_order(params[:order_id], params[:branch_id])
    if order.is_accepted == true
      stageUpdate = update_order_stage(order)
      responce_json(code: 200, message: "Order cooked.", order: order_list_json(order, "", ""))
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  def check_items_list
    order_items = update_items_status(params[:order_items])

    if order_items
      @order.update(pickedup: true, pickedup_at: DateTime.now)
      @order.update(is_ready: true, cooked_at: DateTime.now) unless @order.is_ready
      orderPushNotificationWorker(@order.branch.restaurant&.user, @order.user, "order_onway", "Order On Way", "Transporter will reach your destination shortly for order no #{ @order.id }", @order.id)
      responce_json(code: 200, message: "Items checked", status: @order.order_items.first.is_delivered)
    else
      responce_json(code: 422, message: "Invalid Items")
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

  def validate_user_branch
    @userRole = @user.auths.find_by(role: "business")
    @branch = get_branch(params[:branch_id]) if @userRole
    unless @userRole && @branch
      responce_json(code: 422, message: "Unauthorized Access")
    end
  end

  def validate_branch
    @branch = get_branch(params[:branch_id])
    unless @branch
      responce_json(code: 422, message: "Unauthorized Access")
    end
  end

  def validate_order_delivered
    @userRole = @user.auths.where("role = ? or role = ? or role = ?", "business", "manager", "transporter")
    unless @userRole
      responce_json(code: 422, message: "Invalid user!!")
    end
  end

  def validate_order_checklist
    orderIds = params[:order_items].present? ? params[:order_items].map(&:to_i) : []
    @order = get_order_details(params[:order_id])
    orderItems = @order.order_items.pluck(:id)
    check = (orderItems == orderItems & orderIds)
    unless check
      responce_json(code: 422, message: "Invalid please check all items!!")
    end
  end
end
