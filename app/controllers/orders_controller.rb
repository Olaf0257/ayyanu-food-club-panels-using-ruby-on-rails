class OrdersController < ApplicationController
  before_action :require_admin_logged_in, except: [:driver_performance]

  def order_list
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @orders = get_all_orders(params[:keyword], params[:order_type], params[:delivery_type], params[:country_id], params[:order_status], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: params[:per_page].presence || 20)
        render layout: "admin_application"
      end

      format.js do
        if params[:map].present?
          render "order_map_location"
        else
          @orders = @orders.paginate(page: params[:page], per_page: params[:per_page].presence || 20)
          render "index"
        end
      end

      format.csv { send_data @orders.admin_orders_list_csv((params[:start_date].presence || Date.today), (params[:end_date].presence || Date.today), (is_super_admin?(@admin) || @admin.role_id != 7)), filename: "orders_list.csv" }
    end
  end

  def transporter_order_list
    @transporter = User.find(params[:user_id])
    @start_date = params[:start_date].presence || Date.today - 30
    @end_date = params[:end_date].presence || Date.today
    @orders = Order.where(transporter_id: @transporter.id).where("DATE(orders.created_at) >= ? AND DATE(orders.created_at) <= ?", @start_date, @end_date).order_by_date_desc

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: params[:per_page].presence || 50)
        render layout: "admin_application"
      end

      format.csv { send_data @orders.transporter_order_list_csv(@transporter, @start_date, @end_date), filename: "transporter_order_list.csv" }
    end
  end

  def refund_order_list
    @orders = Order.where(is_cancelled: true).joins(branch: :restaurant).includes(:user, branch: :restaurant)
    @orders = @orders.where(restaurants: { country_id: @admin.country_id }) if @admin.class.name == "User"
    @countries = @orders.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @orders = @orders.where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @orders = @orders.where("orders.id = ? or branches.address like ? or restaurants.title like (?)", params[:keyword].to_s, "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    @orders = @orders.distinct.order_by_date_desc

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @orders.refund_order_list_csv(params[:country_id], params[:start_date], params[:end_date]), filename: "refund_order_list.csv" }
    end
  end

  def view_cancel_notes
    @order = Order.find(params[:order_id])
    @incident = @order.order_incident
    @type = params[:type]

    respond_to do |format|
      format.js { }
      format.csv { send_data @order.incident_report_csv, filename: "incident_report.csv" }
    end
  end

  def order_show
    @order = find_order_id(decode_token(params[:id]))
    @order_items = find_order_orderd_items(@order) if @order.present?
    render layout: "admin_application"
  end

  def driver_performance
    @order = Order.find(params[:order_id])

    respond_to do |format|
      format.html do
        render layout: "admin_application"
      end

      format.csv { send_data @order.driver_performance_csv(session[:admin_user_id] || session[:role_user_id]), filename: "order_driver_performance.csv" }
    end
  end

  def get_user_details
    @user = User.find_by(id: params[:user_id])
  end

  def cancel_order_form
    @order = Order.find(params[:order_id])
    @users = []
    @users << @order.branch.restaurant.user
    @users << @order.branch.branch_managers.map(&:user).flatten.uniq.sort_by(&:name)
    @users << @order.user
    @persons = @users.flatten.uniq.map { |user| [user.auths.first&.role.to_s.titleize + "- " + user.name + " (" + user.email + ")", user.id] }
  end

  def cancel_order
    order = Order.find(params[:order_id])

    if order.is_rejected
      flash[:error] = "Order Already Rejected by Restaurant"
    else
      order.update(is_cancelled: true, cancelled_at: Time.zone.now, cancel_request_by: "", cancellation_reason: "", cancel_notes: "")
      order.transporter&.update(busy: false)
      OrderIncident.create(order_id: order.id, reported_by: params[:person_calling], created_by: @admin.id, complaint_on: params[:incident_type], item_type: params[:item_type], complaint_description: params[:complaint_description], refund_required: params[:refund], witness_name: params[:witness_name], witness_number: params[:witness_number], witness_description: params[:witness_description])
      order_cancel_worker(order.id)
      send_notification_releted_menu("Order Id #{order.id} is Cancelled", "order_cancelled", @admin, get_admin_user, order.branch.restaurant_id)
      orderPushNotificationWorker(@admin, order.user, "order_cancelled", "Order Cancelled", "Order Id #{order.id} is Cancelled", order.id)
      orderPushNotificationWorker(@admin, order.transporter, "order_cancelled", "Order Cancelled", "Order Id #{order.id} is Cancelled", order.id) if order.transporter
      flash[:success] = "Order Cancelled Successfully!"
    end

    redirect_to request.referer
  end

  def refund_order
    order = Order.find(params[:order_id])

    if params[:status] == "refund"
      order.update(refund: true, refund_notes: params[:refund_notes].to_s.squish, refund_fault: params[:refund_fault])
      refund_amount_to_customer(order) if order.total_amount.to_f.positive? && order.transection_id.present? && order.order_type == "prepaid"
      Point.create_point(order, order.user.id, format("%0.03f", order.used_point), "Credit") if order.used_point.to_f.positive?
      deduct_branch_pending_amount(order) if order.is_accepted
      order.branch.update(pending_amount: (order.branch.pending_amount - order.delivery_charge.to_f.round(3))) if order.third_party_delivery && order.refund_fault == "Brand"
      flash[:success] = "Order Refund Successfully!"
    elsif params[:status] == "no_refund"
      order.update(refund: false, refund_notes: params[:refund_notes].to_s.squish, refund_fault: params[:refund_fault])
      order.branch.update(pending_amount: (order.branch.pending_amount - order.delivery_charge.to_f.round(3))) if order.third_party_delivery && order.order_type == "postpaid"
      flash[:success] = "Order No Refund Successfully!"
    end

    redirect_to request.referer
  end

  def take_order
    user = User.find_by(id: decode_token(params[:user_id]))
    auth = user&.auths&.find_by(role: "customer")

    if user && auth
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:customer_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully as " + user.name
    else
      flash[:error] = "User not found"
    end

    redirect_to root_path
  end

  def admin_change_driver
    @order = Order.find(params[:order_id])

    if @order.third_party_delivery
      @drivers = User.joins(:auths, :delivery_company).where(delivery_companies: { approved: true, active: true, country_id: @order.branch.restaurant.country_id }, auths: { role: "transporter" }).idle_drivers.distinct
      @drivers = @drivers.where("users.name like ? OR delivery_companies.name like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    else
      busy_transporter_ids = Order.where(branch_id: @order.branch_id, is_accepted: true, is_delivered: false, is_cancelled: false).where("date(orders.created_at) = ?", Date.today).pluck(:transporter_id).uniq
      @drivers = busy_transporter_ids.present? ? @order.branch.users.where(status: true).where.not(id: busy_transporter_ids) : @order.branch.users.where(status: true)
      @drivers = @drivers.where("users.name like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    end

    @drivers = @drivers.where.not(id: @order.transporter_id).order(:name)
  end

  def admin_update_driver
    order = Order.find(params[:order_id])

    if order && (order.transporter_id != params[:transporter_id].to_i)
      owner = order.third_party_delivery ? order.transporter.delivery_company.users.joins(:auths).where(auths: { role: "delivery_company" }).first : order.branch.restaurant.user
      iou_amount = order.iou&.paid_amount
      order.iou.destroy if order.iou.present?
      firebase = firebase_connection
      group = update_track_order(firebase, order)
      orderPushNotificationWorker(owner, order.transporter, "transporter_remove", "Transporter Removed", "Transporter is removed to Order Id #{params[:order_id]}", params[:order_id])
      order.transporter.update(busy: false) if order.third_party_delivery
      order.update(transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now, driver_accepted_at: nil)
      OrderDriver.create(order_id: order.id, transporter_id: params[:transporter_id], driver_assigned_at: DateTime.now)
      OrderAcceptNotificationWorker.perform_at(1.minutes.from_now, order.id)
      User.find(params[:transporter_id]).update(busy: true) if order.third_party_delivery
      add_iou_in_order(iou_amount, owner, order.id, params[:transporter_id]) if order.order_type == "postpaid"
      orderPushNotificationWorker(owner, order.transporter, "transporter_assigned", "Transporter Assigned", "Transporter is assigned to Order Id #{params[:order_id]}", params[:order_id])
      group = create_track_group(firebase, params[:transporter_id], "26.2285".to_f, "50.5860".to_f)
      flash[:success] = "Transporter Changed Successfully!"
    else
      flash[:error] = "Choose different driver!!"
    end

    redirect_to request.referer
  end

  def all_driver_locations
    company_ids = if @admin.class.name == "SuperAdmin"
                    DeliveryCompany.approved.active
                  else
                    DeliveryCompany.approved.active.search_by_country(@admin.country_id)
                  end

    if params[:restaurant].present?
      @restaurants = Restaurant.all
      @restaurants = @restaurants.where(country_id: @admin.country_id) unless helpers.is_super_admin?(@admin)
      @drivers = User.joins(:auths, :branches).where(branches: { restaurant_id: @restaurants.pluck(:id) }, auths: { role: "transporter" }).reject_ghost_driver.available_drivers.distinct
      @driver_details = @drivers.map { |d| [d.name, d.latitude.to_f, d.longitude.to_f, d.busy, d.vehicle_type.to_s, d.branches.first&.restaurant&.title.to_s] }
    else
      @drivers = User.joins(:auths).where(delivery_company_id: company_ids, auths: { role: "transporter" }).reject_ghost_driver.available_drivers.distinct
      @driver_details = @drivers.map { |d| [d.name, d.latitude.to_f, d.longitude.to_f, d.busy, d.vehicle_type.to_s, d.delivery_company.name] }
    end

    render layout: "admin_application"
  end

  def transporter_history
    @order = Order.find(params[:order_id])
    @drivers = @order.order_drivers.order(created_at: :desc)

    respond_to do |format|
      format.js {}
      format.csv { send_data @drivers.order_driver_history_csv(@order.id), filename: "order_driver_history.csv" }
    end
  end
end
