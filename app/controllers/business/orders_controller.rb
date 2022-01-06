class Business::OrdersController < ApplicationController
  before_action :authenticate_business

  def index
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_type])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.settled_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "settled_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def cancel_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_cancel_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_type])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.rejected_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "rejected_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def admin_cancel_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_admin_cancel_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_type])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.cancelled_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "cancelled_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def dine_in_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_dine_in_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_status], params[:order_type], params[:payment_type])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.dine_in_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "dine_in_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def foodclub_delivery_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_foodclub_delivery_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_type], params[:order_status])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.foodclub_delivery_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "foodclub_delivery_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def foodclub_delivery_cancelled_orders_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      if @user.auth_role == "manager"
        @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).is_subscribed
      else
        @branches = restaurant.branches.is_subscribed
        @restaurants = @user.restaurants
      end

      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @branch = restaurant.branches.find_by(id: params[:branch])
      @orders = filter_foodclub_delivery_cancelled_orders_data(@user, restaurant, @branch, params[:keyword], params[:area], params[:start_date], params[:end_date], params[:order_type])
      @orders = @orders.includes(:branch, :user)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_orders = @orders

      respond_to do |format|
        format.html do
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @orders.foodclub_delivery_cancelled_orders_list_csv(@branch_name, @area_name, @start_date, @end_date), filename: "foodclub_delivery_cancelled_orders_list.csv" }
      end
    else
      redirect_to_root
    end
  end

  def foodclub_delivery_settle_amount
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @restaurants = @user.restaurants
      @all_orders = filter_foodclub_delivery_settle_amount_data(restaurant.branches.pluck(:id), params[:date])
      @grand_total = @all_orders.sum(&:third_party_payable_amount_business)
      @orders = @all_orders.paginate(page: params[:page], per_page: 50)
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end

  def approve_amount_settle
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @restaurants = @user.restaurants
      filter_foodclub_delivery_settle_amount_data(restaurant.branches.pluck(:id), params[:order_date]).update_all(is_settled: true, settled_at: DateTime.current)
      flash[:success] = "Successfully Approved!"
    end

    redirect_to request.referer
  end

  def settle_third_party_order
    order = Order.find(params[:id])
    order.update(is_settled: true, settled_at: DateTime.current)
    flash[:success] = "Order Settled!"
    redirect_to request.referer
  end

  def maneger_branch_order
    @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:id)
    @selected_branch = Branch.find_by(id: params[:branch]) || @branches.first
    @orders = filter_orders_branch_wise(@user, @selected_branch, params[:keyword], params[:status], params[:payment_mode])
    render layout: "partner_application"
  end

  def maneger_cancel_order_list
    @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:id)
    @selected_branch = Branch.find_by(id: params[:branch]) || @branches.first
    @orders = filter_cancel_orders_branch_wise(@user, @selected_branch, params[:keyword], params[:status], params[:payment_mode])
    render layout: "partner_application"
  end

  def maneger_admin_cancel_order_list
    @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:id)
    @selected_branch = Branch.find_by(id: params[:branch]) || @branches.first
    @orders = filter_admin_cancel_orders_branch_wise(@user, @selected_branch, params[:keyword], params[:status], params[:payment_mode])
    render layout: "partner_application"
  end

  def manager_foodclub_delivery_order_list
    @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:id)
    @selected_branch = Branch.find_by(id: params[:branch]) || @branches.first
    @orders = filter_foodclub_delivery_orders_branch_wise(@user, @selected_branch, params[:keyword], params[:status], params[:payment_mode])
    render layout: "partner_application"
  end

  def manager_foodclub_delivery_cancelled_order_list
    @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:id)
    @selected_branch = Branch.find_by(id: params[:branch]) || @branches.first
    @orders = filter_foodclub_delivery_cancelled_orders_branch_wise(@user, @selected_branch, params[:keyword], params[:status], params[:payment_mode])
    render layout: "partner_application"
  end

  def manager_foodclub_delivery_settle_amount
    branch_ids = @user.branch_managers.pluck(:branch_id)
    @all_orders = filter_foodclub_delivery_settle_amount_data(branch_ids, params[:date])
    @grand_total = @all_orders.sum(&:third_party_payable_amount_business)
    @orders = @all_orders.paginate(page: params[:page], per_page: 50)
    render layout: "partner_application"
  end

  def manager_approve_amount_settle
    branch_ids = @user.branch_managers.pluck(:branch_id)
    filter_foodclub_delivery_settle_amount_data(branch_ids, params[:order_date]).update_all(is_settled: true, settled_at: DateTime.current)
    flash[:success] = "Successfully Approved!"
    redirect_to request.referer
  end

  def show
    @order = find_order_id(params[:id])
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    busy_transporter_ids = Order.where(branch_id: @order.branch_id, is_accepted: true, is_delivered: false, is_cancelled: false).where("date(orders.created_at) = ?", Date.today).pluck(:transporter_id).uniq
    @transports = web_branch_transport(@order.branch.id, restaurant, busy_transporter_ids)
    @order_items = find_order_orderd_items(@order).includes(:menu_item, :order_item_addons) if @order.present?
    @branch_coverage_area = BranchCoverageArea.find_by(branch_id: @order.branch_id, coverage_area_id: @order.coverage_area_id)
    render layout: "partner_application"
    rescue Exception => e
  end

  def branch_order
    branch = get_branch_data(params[:id])
    if branch
      @branches = @user.restaurant.branches
      @branch = @user.restaurant.branches.find_by(id: params[:branch])
      @orders = order_by_branch(branch)
      render layout: "partner_application"
    else
      flash[:erorr] = "Branch does not exits!!"
      redirect_back(fallback_location: business_restaurant_branches_path)
    end
  end

  def web_order_action
    user = @user.auths.first.role == "manager" ? @user.branch_managers.first.branch.restaurant.user_id : @user.id
    order = Order.joins(branch: :restaurant).where("restaurants.user_id=? and orders.id=?", user, params[:order_id]).first
    if order
      if !order.is_accepted && !order.is_rejected && !order.is_cancelled
        status = update_order(order, params[:action_for], params[:cancel_resion])
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

  def web_order_move_Kitchen
    order = get_branch_order(params[:order_id], params[:branch_id])
    if order.is_accepted == true
      stageUpdate = update_order_stage(order)
      # order_kitchen_pusher(order)
      responce_json(code: 200, message: "Order cooked.", order: order_list_json(order, "", ""))
    else
      responce_json(code: 422, message: "Invalid Order")
     end
  end

  def assign_foodclub_driver
    order = Order.find(params[:order_id])
    order.update(third_party_delivery: true, changed_delivery: true)
    redirect_to business_transporter_auto_assign_path(order_id: order.id)
  end

  def assign_nearest_transporter_to_order
    order = Order.find(params[:order_id])
    transporters = User.joins(:auths, :delivery_company).where(status: true, busy: false, auths: { role: "transporter" }, delivery_companies: { country_id: order.branch.restaurant.country_id, active: true }).where.not(latitude: nil, longitude: nil, delivery_company_id: nil).distinct
    transporters = transporters.select { |t| t.delivery_company.zone_ids.empty? || t.delivery_company.zone_ids.include?(order.coverage_area.zone_id) } if order.coverage_area.zone_id

    driver_distances = []

    transporters.each do |user|
      next unless order.coverage_area.zone_id.nil? || (order.coverage_area.zone.present? && (user.zone_ids.empty? || user.zone_ids.include?(order.coverage_area.zone_id)))
      branch_state = Geocoder.search([order.branch.latitude, order.branch.longitude]).first.data["address"]["state"]
      user_state = Geocoder.search([user.latitude, user.longitude]).first.data["address"]["state"]

      if branch_state == user_state
        dist = Geocoder::Calculations.distance_between([order.branch.latitude, order.branch.longitude], [user.latitude, user.longitude], units: :km)

        if order.on_demand
          driver_distances << [user, dist] if user.delivery_company_id == 19
        else
          driver_distances << [user, dist]
        end
      end
    end

    delivery_distance = Geocoder::Calculations.distance_between([order.branch.latitude, order.branch.longitude], [order.latitude, order.longitude], units: :km)

    preferred_drivers = if delivery_distance.to_f >= 13 || order.sub_total.to_f >= 30
                          driver_distances.select { |user, _dist| user.vehicle_type == true }
                        else
                          driver_distances.select { |user, _dist| user.vehicle_type == false }
                        end

    driver_distances = preferred_drivers.flatten.present? ? preferred_drivers : driver_distances
    nearest_driver_id = driver_distances.min_by { |_x, y| y }&.first&.id

    if nearest_driver_id.blank?
      max_drivers = User.joins(:delivery_company).where(delivery_companies: { country_id: order.branch.restaurant.country_id, active: true })
      max_drivers = max_drivers.select { |t| t.delivery_company.zone_ids.empty? || t.delivery_company.zone_ids.include?(order.coverage_area.zone_id) } if order.coverage_area.zone_id
      max_driver_company = User.where(id: max_drivers.map(&:id)).joins(:delivery_company).select(:delivery_company_id).group(:delivery_company_id).order("count(delivery_company_id) desc").first&.delivery_company
      max_driver_company = DeliveryCompany.find(19) if order.on_demand
      nearest_driver_id = max_driver_company&.users&.find_by(name: "Food Club Driver")&.id
      send_notification_to_delivery_company(@user, nearest_driver_id, order)
    end

    redirect_to business_transporter_assign_path(user_id: (order.transporter_id || nearest_driver_id), order_id: order.id, amount: 0)
  end

  def assign_dine_in_order
    order = Order.find(params[:order_id])
    driver = get_dine_in_transporter
    redirect_to business_transporter_assign_path(user_id: (order.transporter_id || driver.id), order_id: order.id, amount: 0)
  end

  def web_add_transporter_to_order
    user = find_user(params[:user_id])

    if user&.status
      order = add_order_transport(@user, params[:order_id], params[:user_id], params[:amount])
      if order[:status]
        User.find(params[:user_id]).update(busy: true) if order[:order].third_party_delivery
        orderPushNotificationWorker(@user, order[:user], "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
        firebase = firebase_connection
        group = create_track_group(firebase, params[:user_id], "26.2285".to_f, "50.5860".to_f)
        stageUpdate = web_update_order_stage(order[:order])
        order_kitchen_pusher(order[:order])

        if request.get?
          flash[:success] = "Transporter assigned"
          redirect_to business_view_order_path(restaurant_id: encode_token(order[:order].branch.restaurant_id), id: order[:order].id)
        else
          responce_json(code: 200, message: "Transporter assigned", order: order_transporter_json(order[:order]))
        end
      else
        if request.get?
          flash[:success] = "Invalid Order"
          redirect_to business_view_order_path(restaurant_id: encode_token(order[:order].branch.restaurant_id), id: order[:order].id)
        else
          responce_json(code: 422, message: "Invalid Order")
        end
      end
    else
      if request.get?
        flash[:error] = "No transporter available!!"
        redirect_to business_view_order_path(restaurant_id: encode_token(Order.find(params[:order_id]).branch.restaurant_id), id: params[:order_id])
      else
        responce_json(code: 422, message: "No transporter available!!")
      end
    end
  end

  def web_order_update_stage
    order = find_order_id(params[:order_id])
    if order
      if order.is_ready == true
        order.update(pickedup: true, pickedup_at: DateTime.now)
        orderPushNotificationWorker(@user, order.user, "order_onway", "Order On Way", "Transporter will reach your destination shortly for order no #{params[:order_id]}", params[:order_id])
        responce_json(code: 200, message: "Order On way", order: order_show_json(order, ""))
      else
        responce_json(code: 422, message: "Order not cooked!!")
      end
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  def web_order_delivered
    order = (@user.auths.first.role == "business") || (@user.auths.first.role == "manager") ? update_order_status(params[:order_id], params[:branch_id], @user.auths.first.role) : update_order_delivered_status(params[:order_id], @user)
    firebase = firebase_connection
    # order[:status] ? delete_driver_from_groups(firebase,order[:order].transporter_id,order[:order].id) : ""
    if order[:status]
      # delete_driver_from_groups(firebase,order[:order].transporter_id,order[:order].id)
      orderPushNotificationWorker(@user, order[:order].user, "order_delivered", "Order Delivered", "Order Id #{order[:order].id} is delivered", order[:order].id)
      create_track_group(firebase, order[:order].transporter_id, "26.2285".to_f, "50.5860".to_f)
      order[:order].transporter.update(busy: false)
      responce_json(code: 200, message: "Order delivered", order: order_status_json(order[:order]))
    else
      responce_json(code: 422, message: "Invalid Order")
    end
  end

  def business_update_transporter_in_order
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
      orderPushNotificationWorker(@user, order.transporter, "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
      group = create_track_group(firebase, params[:transporter_id], "26.2285".to_f, "50.5860".to_f)
      responce_json(code: 200, message: "Order", order: order_transporter_json(order))
    else
      responce_json(code: 422, message: "Can't update the driver!! Please select different driver")
    end
  end

  def order_invoice
    @order = find_order_id(params[:id])
    @invoice = order_show_json(@order, "")
    render layout: "partner_application"
    rescue Exception => e
  end

  def manager_order_invoice
    @order = find_order_id(params[:id])
    @invoice = order_show_json(@order, "")
    render layout: "partner_application"
    rescue Exception => e
  end

  def live_order_tracking
    @order = find_order_id(params[:id])
    if @order
      @driver = @order.transporter
      @branch = @order.branch
      render layout: "partner_application"
    else
      redirect_to "order_show_path"
    end
  end

  def web_order_cancel_action
    user = @user.auths.first.role == "manager" ? @user.branch_managers.first.branch.restaurant.user_id : @user.id
    order = Order.joins(branch: :restaurant).where("restaurants.user_id=? and orders.id=?", user, params[:order_id]).first
    if order
      if !order.is_rejected && !order.is_cancelled
        status = update_order(order, "reject", params[:cancel_resion])
        if status
          orderPushNotificationWorker(@user, order.user, "order_reject", "Order #{order.is_accepted ? 'Accepted' : 'Rejected'}", "Order Id #{order.id} is #{order.is_accepted ? 'Accepted' : 'Rejected'}", order.id)
          redirect_to business_view_order_path(restaurant_id: params[:restaurant_id], id: order.id)
        else
          redirect_to business_view_order_path(restaurant_id: params[:restaurant_id], id: order.id)
        end
      else
        redirect_to business_view_order_path(restaurant_id: params[:restaurant_id], id: order.id)
      end
    else
      redirect_to business_view_order_path(restaurant_id: params[:restaurant_id], id: order.id)
    end
  end

  def edit_dine_in_order
    @order = Order.find(params[:order_id])
  end

  def update_dine_in_order
    @order = Order.find(params[:order_id])
    @order.update(order_type: params[:order_mode], payment_mode: params[:order_mode] == "prepaid" ? "online" : (params[:order_mode] == "postpaid") ? "COD" : "CCM")

    if params[:order_type] == "Dine In"
      @order.update(table_number: params[:table_number])
    else
      @order.update(table_number: nil)
    end

    flash[:success] = "Order Successfully Updated!"
    redirect_to request.referer
  end
end
