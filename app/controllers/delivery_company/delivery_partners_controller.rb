class DeliveryCompany::DeliveryPartnersController < ApplicationController
  before_action :authenticate_business, except: [:driver_shift_list]

  def dashboard
    @all_users = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    @active_orders_count = Order.where(is_delivered: false, is_cancelled: false, transporter_id: @all_users.pluck(:id)).uniq.count
    @delivered_orders_count = Order.where(is_delivered: true, transporter_id: @all_users.pluck(:id)).uniq.count
    @cancelled_orders_count = Order.where(is_cancelled: true, transporter_id: @all_users.pluck(:id)).uniq.count
    @idle_drivers_count = @all_users.idle_drivers.uniq.count
    @on_the_way_drivers_count = @all_users.busy_drivers.uniq.count
    @offline_drivers_count = @all_users.offline_drivers.uniq.count
    @keyword = params[:keyword].presence || "day"
    @earningGraphData = delivery_company_earning_graphdata(@keyword, @user.delivery_company)

    respond_to do |format|
      format.html { render layout: "partner_application" }
      format.js { render "index" }
    end
  end

  def transporters
    @transporters = filter_delivery_company_transport(params[:keyword], params[:cpr_number], params[:vehicle_type])
    vehicle_type = params[:vehicle_type] || "NA"

    @zones = if @user.delivery_company.zones.present?
               @user.delivery_company.zones.pluck(:name, :id).sort
             else
               Zone.joins(district: :state).where(states: { country_id: @user.delivery_company.country_id }).distinct.pluck(:name, :id).sort
             end

    respond_to do |format|
      format.html do
        @transporters = @transporters
        render layout: "partner_application"
      end

      format.csv { send_data @transporters.transporters_list_csv, filename: "transporters_list_csv.csv" }
    end
  end

  def current_drivers_list
    @state = params[:state]
    @all_users = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    @all_users = @all_users.where("users.cpr_number = ? OR users.id = ? OR users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?

    @users = if @state == "busy"
               @all_users.busy_drivers.uniq
             elsif @state == "idle"
               @all_users.idle_drivers.uniq
             elsif @state == "offline"
               @all_users.offline_drivers.uniq
             else
               []
             end

    @users = @users.paginate(page: params[:page], per_page: 50)
    render layout: "partner_application"
  end

  def active_orders_list
    @state = params[:state]
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    @orders = Order.includes(:transporter, branch: :restaurant).where(transporter_id: @transporters.pluck(:id))
    @restaurants = Restaurant.where(id: @orders.map(&:branch).flatten.map(&:restaurant_id).uniq).pluck(:title, :id).sort

    @orders = if @state == "active"
                @orders.where(is_delivered: false, is_cancelled: false)
              elsif @state == "cancelled"
                @orders.where(is_cancelled: true)
              elsif @state == "disputed"
                @orders.disputed_orders
              elsif @state == "total"
                @orders
              elsif @state == "settled"
                @orders.settled
              elsif @state == "returned"
                @orders.returned_orders
              else
                @orders.where(is_delivered: true)
              end

    @orders = @orders.joins(:transporter).where("users.cpr_number = ? or orders.id = ? or users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%").distinct if params[:keyword].present?
    @orders = @orders.where(branches: { restaurant_id: params[:restaurant_id] }) if params[:restaurant_id].present?
    @orders = @orders.where(order_type: params[:order_type]) if params[:order_type].present?
    @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?

    if params[:order_status].present?
      orders = @orders.select { |o| o.current_status == params[:order_status] }
      @orders = Order.includes(:transporter, branch: :restaurant).where(id: orders.map(&:id))
    end

    @orders = @orders.order_by_date_desc
    @all_orders = @orders

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @orders.active_order_list_csv(@state), filename: "#{@state}_orders_list.csv" }
    end
  end

  def new_transporters
    @zones = if @user.delivery_company.zones.present?
               @user.delivery_company.zones.pluck(:name, :id).sort
             else
               Zone.joins(district: :state).where(states: { country_id: @user.delivery_company.country_id }).distinct.pluck(:name, :id).sort
             end

    render layout: "partner_application"
  end

  def add_transporters
    user = get_user_cpr_number(params[:cpr_number])

    if params[:cpr_number].present? && params[:password].present?
      if user
        flash[:error] = "Cpr Number Already Exists"
        redirect_to delivery_company_new_transporters_path
      else
        create_delivery_transporter(params[:firstname], params[:cpr_number] + "@gmail.com", "transporter", params[:contact], params[:country_code], params[:password], params[:image], params[:cpr_number], @user.delivery_company_id, params[:zone_ids], params[:vehicle_type])
        flash[:success] = "Transporter Created Successfully"
        redirect_to delivery_company_transporters_path
      end
    else
      flash[:error] = "Required parameter is missing!!"
      redirect_to delivery_company_new_transporters_path
    end
  end

  def update_transporters
    user = User.find_by(id: params[:user_id])

    if user
      update_delivery_transporter(user, params[:firstname], params[:contact].strip, params[:country_code], params[:image], params[:zone_ids], params[:vehicle_type])
      flash[:success] = "Transporter Details Updated Successfully!"
    else
      flash[:error] = "User does not exist"
    end

    redirect_to delivery_company_transporters_path
  end

  def change_driver
    order = find_order_id(params[:order_id])

    if order && (order.transporter_id != params[:transporter_id].to_i)
      order.iou.destroy if order.iou.present?
      firebase = firebase_connection
      group = update_track_order(firebase, order)
      orderPushNotificationWorker(@user, order.transporter, "transporter_remove", "Transporter Removed", "Transporter is removed to Order Id #{params[:order_id]}", params[:order_id])
      order.transporter.update(busy: false)
      order.update(transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now, driver_accepted_at: nil)
      OrderDriver.create(order_id: order.id, transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now)
      OrderAcceptNotificationWorker.perform_at(1.minutes.from_now, order.id)
      User.find(params[:transporter_id]).update(busy: true)
      add_iou_in_order(order.total_amount.to_f.round(3), @user, order.id, params[:transporter_id]) if order.order_type == "postpaid"
      orderPushNotificationWorker(@user, order.transporter, "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
      group = create_track_group(firebase, params[:transporter_id], "26.2285".to_f, "50.5860".to_f)
      responce_json(code: 200, message: "Order", order: order_transporter_json(order))
    else
      responce_json(code: 422, message: "Choose different driver!!")
    end
  end

  def track_drivers
    @delivery_company = @user.delivery_company
    @drivers = @delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).reject_ghost_driver.available_drivers
    @driver_details = @drivers.map { |d| [d.name, d.latitude.to_f, d.longitude.to_f, d.busy, d.vehicle_type.to_s] }
    render layout: "partner_application"
  end

  def free_driver
    @user = User.find(params[:driver_id])
    @user.update(busy: false)
    flash[:success] = "Driver is free now!"
    redirect_to delivery_company_active_orders_list_path(state: "active")
  end

  def ious_list
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).distinct
    @ious = Iou.where(transporter_id: @transporters.pluck(:id)).includes(:transporter, order: { branch: { restaurant: :country } })
    @restaurants = Restaurant.where(id: @ious.map(&:order).flatten.map(&:branch).flatten.map(&:restaurant_id).uniq).pluck(:title, :id)
    @ious = @ious.where(branches: { restaurant_id: params[:searched_restaurant_id] }) if params[:searched_restaurant_id].present?
    @ious = @ious.joins(:transporter).where("ious.order_id = ? OR cpr_number = ?", params[:keyword], params[:keyword]).distinct if params[:keyword].present?
    @ious = @ious.where("DATE(ious.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @ious = @ious.where("DATE(ious.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @ious = @ious.order_by_date_desc

    respond_to do |format|
      format.html do
        @ious = @ious.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @ious.delivery_company_ious_list_csv, filename: "manage_iou_list.csv" }
    end
  end

  def paid_iou
    iou = find_iou(params[:iou_id])

    if iou
      order = find_order_id(iou.order.id)

      if order.is_cancelled == true || order.is_delivered == true
        updateIou = iou.update(is_received: true)
        send_json_response("Iou paid", "success", {})
      else
        send_json_response("Invalid order not delivered", "invalid", {})
      end
    else
      send_json_response("Invalid transporter", "invalid", {})
    end
  end

  def settle_amount
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    @pending_orders = Order.pending_settle_list(@transporters.pluck(:id), params[:date]&.to_date)
    @pending_order_dates = Order.where(id: @pending_orders.reject { |o| o.iou&.is_received == false }).pluck("date(created_at)").uniq.map { |i| i.strftime("%Y/%m/%d") }.join(", ")
    @all_orders = Order.settle_amount_list(@transporters.pluck(:id), params[:date]&.to_date)
    @all_orders = Order.where(id: @all_orders.reject { |o| o.iou&.is_received == false })
    @grand_total = @all_orders.sum(&:third_party_payable_amount)
    @pending_grand_total = @all_orders.where(payment_approved_at: nil).sum(&:third_party_payable_amount)
    @orders = @all_orders.paginate(page: params[:page], per_page: 50)
    render layout: "partner_application"
  end

  def send_amount_settle_approval
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    orders = Order.settle_amount_list(@transporters.pluck(:id), params[:order_date]&.to_date)
    orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false })
    orders = orders.where(payment_approved_at: nil, payment_approval_pending: false)
    orders.update_all(payment_approval_pending: true, payment_approved_at: nil, payment_rejected_at: nil, payment_reject_reason: nil)
    msg = @user.delivery_company.name + " Company has sent amount of " + params[:order_date].to_date.strftime("%Y/%m/%d") + " for approval."
    send_amount_settle_notification_to_admin(msg, "settle_delivery_company_amount", @user, get_admin_user, @user.delivery_company_id)
    flash[:success] = "Amount Settle Request has been sent to Admin!"
    redirect_to request.referer
  end

  def driver_shift_list
    @user = User.find(params[:user_id])
    @shifts = @user.delivery_company_shifts.order(:day, :start_time)
  end

  def edit_password
    render layout: "partner_application"
  end

  def change_password
    @user = find_user(params[:user_id])
    auth = @user.auths.find_by(role: "transporter") || @user.auths.find_by(role: "delivery_company")

    if (auth&.role == "transporter") || (auth&.role == "delivery_company" && auth&.valid_password?(params[:old_password]))
      auth.update(password: params[:new_password])
      responce_json(code: 200, message: "Password changed successfully")
    else
      responce_json(code: 404, message: "Old password doesn't match")
    end
  end

  def remove_transporter
    user = User.find_by(id: params[:emp_id])

    if user
      user.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "User does not exists"
      render json: { code: 404 }
    end
  end

  def driver_review_report
    @ratings = Rating.active.includes(:branch, { order: :transporter }).joins(:branch, { order: :transporter }).where("users.delivery_company_id = ?", @user.delivery_company_id).distinct
    @restaurants = Restaurant.where(id: @ratings.pluck("branches.restaurant_id").uniq).pluck(:title, :id).sort
    @ratings = @ratings.where(branches: { restaurant_id: params[:searched_restaurant_id] }) if params[:searched_restaurant_id].present?
    @ratings = @ratings.where("orders.id = ? OR users.name like ?", params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
    @ratings = @ratings.where("DATE(ratings.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @ratings = @ratings.where("DATE(ratings.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @ratings = @ratings.order(id: :desc)
    @all_ratings = @ratings

    respond_to do |format|
      format.html do
        @ratings = @ratings.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @ratings.delivery_company_driver_rating_csv(params[:searched_restaurant_id], @user.delivery_company, params[:start_date], params[:end_date]), filename: "delivery_company_driver_rating.csv" }
    end
  end

  def driver_timing_report
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).reject_ghost_driver.distinct
    @transporters = @transporters.where("users.cpr_number = ? OR users.id = ? OR users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
    @transporters = @transporters.order(:id).paginate(page: params[:page], per_page: 50)
    render layout: "partner_application"
  end

  def driver_timing
    @transporter = User.find(params[:user_id])
    @timings = @transporter.transporter_timings.order(id: :desc)
    @timings = @timings.where("DATE(transporter_timings.created_at) >= ? AND DATE(transporter_timings.created_at) <= ?", (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date)

    respond_to do |format|
      format.html do
        @timings = @timings.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @timings.driver_timing_list_csv(@transporter, (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date), filename: "driver_timing_list.csv" }
    end
  end

  def delivery_company_earning_graphdata(keyword, company)
    todayDate = Date.today

    case keyword
    when "day"
      @total_income = delivery_company_day_earnings("income", todayDate, company)
      @total_orders = delivery_company_day_earnings("orders", todayDate, company)
    when "week"
      @total_income = delivery_company_week_earnings("income", todayDate, company)
      @total_orders = delivery_company_week_earnings("orders", todayDate, company)
    when "month"
      @total_income = delivery_company_month_earnings("income", todayDate, company)
      @total_orders = delivery_company_month_earnings("orders", todayDate, company)
    when "year"
      @total_income = delivery_company_year_earnings("income", todayDate, company)
      @total_orders = delivery_company_year_earnings("orders", todayDate, company)
    else
      @total_income = {}
      @total_orders = {}
    end

    result = []

    @total_income.keys.reverse.each do |key|
      graphIncomeItem = {}
      graphIncomeItem["y"] = key
      graphIncomeItem["a"] = @total_income[key]
      graphIncomeItem["b"] = @total_orders[key]
      result << graphIncomeItem
    end

    result
  end
end
