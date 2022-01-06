class DeliveryCompaniesController < ApplicationController
  before_action :require_admin_logged_in

  def index
    if @admin.class.name == "SuperAdmin"
      @companies = DeliveryCompany.where(approved: true)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @companies = DeliveryCompany.where(approved: true, country_id: country_id)
    end

    @countries = Country.where(id: @companies.pluck(:country_id).uniq).pluck(:name, :id).sort
    @states = @companies.joins(zones: { district: :state }).distinct.pluck("states.name, states.id").sort
    @zones = Zone.joins(:delivery_companies).where(delivery_companies: { id: @companies.pluck(:id) }).distinct.pluck(:name, :id).sort
    @companies = @companies.search_by_name(params[:keyword]) if params[:keyword].present?
    @companies = @companies.search_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @companies = @companies.search_by_state(params[:searched_state_id]) if params[:searched_state_id].present?
    @companies = @companies.search_by_zone(params[:searched_zone_id]) if params[:searched_zone_id].present?
    @companies = @companies.where("DATE(delivery_companies.created_at) >= ?", params[:start_date]) if params[:start_date].present?
    @companies = @companies.where("DATE(delivery_companies.created_at) <= ?", params[:end_date]) if params[:end_date].present?

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @companies.delivery_company_list_csv, filename: "delivery_company_list.csv" }
    end
  end

  def requested_list
    if @admin.class.name == "SuperAdmin"
      @companies = DeliveryCompany.where(approved: false, rejected: false)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @companies = DeliveryCompany.where(approved: false, rejected: false, country_id: country_id)
    end

    @countries = Country.where(id: @companies.pluck(:country_id).uniq).pluck(:name, :id).sort
    @states = @companies.joins(zones: { district: :state }).distinct.pluck("states.name, states.id").sort
    @zones = Zone.joins(:delivery_companies).where(delivery_companies: { id: @companies.pluck(:id) }).distinct.pluck(:name, :id).sort
    @companies = @companies.search_by_name(params[:keyword]) if params[:keyword].present?
    @companies = @companies.search_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @companies = @companies.search_by_state(params[:searched_state_id]) if params[:searched_state_id].present?
    @companies = @companies.search_by_zone(params[:searched_zone_id]) if params[:searched_zone_id].present?
    @companies = @companies.where("DATE(delivery_companies.created_at) >= ?", params[:start_date]) if params[:start_date].present?
    @companies = @companies.where("DATE(delivery_companies.created_at) <= ?", params[:end_date]) if params[:end_date].present?

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @companies.requested_delivery_company_list_csv, filename: "requested_delivery_company_list.csv" }
    end
  end

  def rejected_list
    if @admin.class.name == "SuperAdmin"
      @companies = DeliveryCompany.where(rejected: true)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @companies = DeliveryCompany.where(rejected: true, country_id: country_id)
    end

    @countries = Country.where(id: @companies.pluck(:country_id).uniq).pluck(:name, :id).sort
    @states = @companies.joins(zones: { district: :state }).distinct.pluck("states.name, states.id").sort
    @zones = Zone.joins(:delivery_companies).where(delivery_companies: { id: @companies.pluck(:id) }).distinct.pluck(:name, :id).sort
    @companies = @companies.search_by_name(params[:keyword]) if params[:keyword].present?
    @companies = @companies.search_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @companies = @companies.search_by_state(params[:searched_state_id]) if params[:searched_state_id].present?
    @companies = @companies.search_by_zone(params[:searched_zone_id]) if params[:searched_zone_id].present?
    @companies = @companies.where("delivery_companies.rejected_at IS NOT NULL AND DATE(delivery_companies.rejected_at) >= ?", params[:start_date]) if params[:start_date].present?
    @companies = @companies.where("delivery_companies.rejected_at IS NOT NULL AND DATE(delivery_companies.rejected_at) <= ?", params[:end_date]) if params[:end_date].present?

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @companies.rejected_delivery_company_list_csv, filename: "rejected_delivery_company_list.csv" }
    end
  end

  def new
    @delivery_company = DeliveryCompany.new

    if @admin.class.name != "SuperAdmin"
      country_code = CountryStateSelect.countries_collection.select { |i| i.first == @admin.country.name }.first.last
      @states = CS.states(country_code).values.sort
    end

    render layout: "admin_application"
  end

  def create
    @delivery_company = DeliveryCompany.create(delivery_company_params)
    @delivery_company.update(contact_no: params[:full_phone]) if params[:full_phone].present?

    if @admin.class.name != "SuperAdmin"
      country_id = @admin.class.find(@admin.id)[:country_id]
      @delivery_company.country_id = country_id
    end

    agreement_url = params[:delivery_company][:agreement].present? ? upload_multipart_image(params[:delivery_company][:agreement], "admin") : ""
    @delivery_company.agreement = agreement_url

    if @delivery_company.save
      params[:zone_ids]&.each do |zone_id|
        @delivery_company.zones << Zone.find(zone_id)
      end

      flash[:success] = "Delivery Company Created Successfully!"
      redirect_to requested_list_delivery_companies_path
    else
      flash[:error] = @delivery_company.errors.full_messages.first.to_s
      redirect_to new_delivery_company_path
    end
  end

  def edit
    session[:return_to] = request.referer
    @delivery_company = DeliveryCompany.find(params[:id])
    country_code = CountryStateSelect.countries_collection.select { |i| i.first == @delivery_company.country.name }.first.last
    @states = CS.states(country_code).values.sort
    state_ids = State.where(country_id: @delivery_company.country_id, name: @states).pluck(:id)
    @districts = District.where(state_id: state_ids)
    @zones = Zone.where(district_id: @districts.pluck(:id)).pluck(:name, :id).sort
    @selected_zones = @delivery_company.zones
    @selected_districts = District.where(id: @selected_zones.pluck(:district_id))
    @selected_states = State.where(id: @selected_districts.pluck(:state_id))
    render layout: "admin_application"
  end

  def update
    @delivery_company = DeliveryCompany.find(params[:id])
    @company_owner = @delivery_company.users.joins(:auths).where(auths: { role: "delivery_company" }).first

    if @delivery_company.update(delivery_company_params)
      @delivery_company.update(contact_no: params[:full_phone]) if params[:full_phone].present?
      state_id = @delivery_company.country.states.find_or_create_by(name: params[:state])&.id
      @delivery_company.update(state_id: state_id)
      prev_img = @delivery_company.agreement.present? ? @delivery_company.agreement.split("/").last : "n/a"
      agreement_url = params[:delivery_company][:agreement].present? ? update_multipart_image(prev_img, params[:delivery_company][:agreement], "admin") : @delivery_company.agreement
      @delivery_company.update(agreement: agreement_url)
      @delivery_company.zones.destroy_all

      params[:zone_ids]&.each do |zone_id|
        @delivery_company.zones << Zone.find(zone_id)
      end

      if @company_owner
        if @company_owner.email != @delivery_company.email
          data = @delivery_company.email
          EmailOnDeliveryCompanyDetailsUpdate.perform_async(@company_owner.email, @company_owner.name, data)
        end

        @company_owner.update(name: @delivery_company.name, email: @delivery_company.email, contact: @delivery_company.contact_no, country_id: @delivery_company.country_id)
      end

      flash[:success] = "Delivery Company Updated Successfully!"
      redirect_to session.delete(:return_to)
    else
      flash[:error] = @delivery_company.errors.full_messages.first.to_s
      redirect_to edit_delivery_company_path(@delivery_company.id)
    end
  end

  def state_list
    country = params[:country].presence
    country_code = CountryStateSelect.countries_collection.select { |i| i.first == country }.first.last
    @states = CS.states(country_code).values.sort
  end

  def district_list
    country_id = params[:country_id]
    state_ids = State.where(country_id: country_id, name: params[:states].to_s.split(",")).pluck(:id)
    @districts = District.where(state_id: state_ids).pluck(:name, :id).sort
  end

  def zone_list
    district_ids = params[:district_ids].to_s.split(",")
    @zones = Zone.where(district_id: district_ids).pluck(:name, :id).sort
  end

  def driver_locations
    @delivery_company = DeliveryCompany.find(params[:id])
    @drivers = @delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).reject_ghost_driver.available_drivers
    @driver_details = @drivers.map { |d| [d.name, d.latitude.to_f, d.longitude.to_f, d.busy, d.vehicle_type.to_s] }
    render layout: "admin_application"
  end

  def settle_amount_list
    @delivery_company = DeliveryCompany.find(params[:id])
    @transporters = @delivery_company.users.joins(:auths).where(auths: { role: "transporter" })
    @pending_orders = Order.admin_pending_settle_list(@transporters.pluck(:id), params[:date]&.to_date)
    @pending_order_dates = Order.where(id: @pending_orders.reject { |o| o.iou&.is_received == false }).pluck("date(created_at)").uniq.sort.map { |i| i.strftime("%Y/%m/%d") }.join(", ")
    orders = Order.admin_settle_amount_list(@transporters.pluck(:id), params[:start_date]&.to_date, params[:end_date]&.to_date)
    @orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false })
    @grand_total = @orders.sum(&:third_party_payable_amount)

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @orders.settle_amount_list_csv((params[:start_date].presence || Date.today), (params[:end_date].presence || Date.today), @delivery_company), filename: "settle amount list csv.csv" }
    end
  end

  def settle_amount
    @delivery_company = DeliveryCompany.find(params[:company_id])
    @transporters = @delivery_company.users.joins(:auths).where(auths: { role: "transporter" })

    if params[:approve].present?
      orders = Order.admin_settle_amount_list(@transporters.pluck(:id), params[:start_date]&.to_date, params[:end_date]&.to_date)
      orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false })
      orders = orders.where(id: params[:order_id]) if params[:order_id].present?
      branch_ids = orders.pluck(:branch_id).uniq
      orders.update_all(payment_approval_pending: false, payment_approved_at: DateTime.now, payment_rejected_at: nil, payment_reject_reason: nil, is_settled: true, settled_at: DateTime.current)
      if params[:order_id].present?
        msg = "Amount Settled for Order " + params[:order_id]
      else
        msg = "Amount Settled for Orders from " + params[:start_date].to_date.strftime("%Y/%m/%d") + " to " + params[:end_date].to_date.strftime("%Y/%m/%d")
      end
      send_amount_settle_notification_to_delivery_company(get_admin_user, @delivery_company, "amount_settle_approved", msg)
      DeliveryCompanySettlementWorker.perform_async(@delivery_company.email, "approved", nil, msg)

      branch_ids.each do |branch_id|
        DeliveryCompanySettlementWorker.perform_async(Branch.find(branch_id).restaurant.user.email, "approved", nil, msg)
      end

      flash[:success] = "Approved Successfully!"

    else
      orders = Order.admin_settle_amount_list(@transporters.pluck(:id), params[:start_date]&.to_date, params[:end_date]&.to_date)
      orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false })
      orders = orders.where(id: params[:order_id]) if params[:order_id].present?
      orders.update_all(payment_approval_pending: false, payment_approved_at: nil, payment_rejected_at: DateTime.now, payment_reject_reason: params[:reject_reason])
      if params[:order_id].present?
        msg = "Amount Settle Rejected for Order " + params[:order_id]
      else
        msg = "Amount Settle Rejected for Orders from " + params[:start_date].to_date.strftime("%Y/%m/%d") + " to " + params[:end_date].to_date.strftime("%Y/%m/%d")
      end
      send_amount_settle_notification_to_delivery_company(get_admin_user, @delivery_company, "amount_settle_rejected", msg)
      DeliveryCompanySettlementWorker.perform_async(@delivery_company.email, "rejected", params[:reject_reason], msg)
      flash[:success] = "Rejected Successfully!"
    end

    redirect_to request.referer
  end

  def approve
    @delivery_company = DeliveryCompany.find(params[:id])

    if User.find_by(email: @delivery_company.email)
      flash[:error] = "User already present with this email."
    else
      @delivery_company.update(approved: true, rejected: false, reject_reason: "", approved_at: Time.zone.now, rejected_at: nil)
      ghost_user = @delivery_company.users.find_or_create_by(name: "Food Club Driver", email: "foodclub_driver#{@delivery_company.id}@gmail.com", country_code: "", contact: "")
      ghost_user.auths.create(role: "transporter", password: "123456")
      create_delivery_company_user(@delivery_company)
      flash[:success] = "Delivery Company Approved Successfully!"
    end

    redirect_to request.referer
  end

  def reject
    @delivery_company = DeliveryCompany.find(params[:id])
    @delivery_company.update(approved: false, rejected: true, reject_reason: params[:reject_reason].to_s.strip, approved_at: nil, rejected_at: Time.zone.now)
    flash[:success] = "Delivery Company Rejected Successfully!"
    DeliveryCompanyWorker.perform_async(@delivery_company.email, @delivery_company.name, @delivery_company.reject_reason, "rejected")
    redirect_to request.referer
  end

  def activate
    @delivery_company = DeliveryCompany.find(params[:id])
    @delivery_company.update(active: true)
    flash[:success] = "Delivery Company Activated Successfully!"
    redirect_to request.referer
  end

  def deactivate
    @delivery_company = DeliveryCompany.find(params[:id])
    @delivery_company.update(active: false)
    flash[:success] = "Delivery Company Deactivated Successfully!"
    redirect_to request.referer
  end

  def destroy
    @delivery_company = DeliveryCompany.find(params[:id])
    @delivery_company.destroy
    flash[:success] = "Delivery Company Deleted Successfully!"
    redirect_to request.referer
  end

  def login_as_company
    company = DeliveryCompany.find(params[:id])
    user = company.users.joins(:auths).where(auths: { role: "delivery_company" }).first
    auth = user&.auths&.find_by(role: "delivery_company")

    if user && auth
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:partner_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully as " + user.name
      redirect_to delivery_company_dashboard_path
    else
      flash[:error] = "User not found"
      redirect_to root_path
    end
  end

  def edit_delivery_company_password
    @delivery_company = DeliveryCompany.find(params[:delivery_company_id])
    render layout: "admin_application"
  end

  def change_delivery_company_password
    @delivery_company = DeliveryCompany.find(params[:delivery_company_id])
    @company_owner = @delivery_company.users.joins(:auths).where(auths: { role: "delivery_company" }).first
    auth = @company_owner&.auths&.first

    if auth&.update(password: params[:password])
      flash[:success] = "Password changed successfully!"
      redirect_to delivery_companies_path
    else
      flash[:error] = "Password does not match"
      redirect_to edit_delivery_company_password_path(delivery_company_id: @delivery_company.id)
    end
  end

  private

  def delivery_company_params
    params.require(:delivery_company).permit(:name, :email, :contact_no, :address1, :address2, :address3, :country_id, :agreement)
  end
end
