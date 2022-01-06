class UsersController < ApplicationController
  before_action :require_admin_logged_in

  def list
    @countries = Country.where(id: User.joins(:auths).where(auths: { role: params[:role] }).pluck(:country_id).uniq).pluck(:name, :id).sort
    @states = State.where(id: User.joins(:delivery_company).pluck("delivery_companies.state_id").uniq).pluck(:name, :id).sort
    @companies = DeliveryCompany.joins(users: :auths).where(auths: { role: "transporter" }).distinct.pluck(:name, :id).sort
    @restaurants = Restaurant.joins(:branches).where(branches: { id: User.joins(:branches).pluck("branches.id") }).distinct.pluck(:title, :id).sort
    @users = search_user_list(params[:role], params[:keyword], "", params[:searched_country_id], params[:searched_state_id], params[:searched_company_id], params[:searched_restaurant_id], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @users = @users.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @users.user_list_csv(params[:role]), filename: "user_list.csv" }
    end
  end

  def profile
    @user = find_user(decode_token(params[:id]))
    @selected_user = User.find_by id: params[:selected_user_id]
    @trans_order = Order.includes(:branch).where(transporter_id: @user.id)
    manager = BranchManager.find_by(user_id: @user.id)
    manager_branch = manager.branch if manager.present?
    @orders = manager_branch.orders.includes(:branch) if manager_branch.present?
    @customer_orders = @user.orders.includes(branch: :restaurant).order_by_date_desc.paginate(per_page: 25, page: params[:page]) if @user.auths.last.role == "customer"
    render layout: (params[:is_view_address] == 'true' ? "partner_application" : "admin_application")
  end

  def all_payment_data_restaurant_wise
    # @data = get_payment_data_restaurant_wise(params[:keyword])
    if @admin.class.name == "SuperAdmin"
      if params[:keyword].present?
        @data = Restaurant.joins(:branches).where("title LIKE (?) and is_subscribe = ? and branches.is_approved=?", "%#{params[:keyword]}%", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
      else
        @data = Restaurant.joins(:branches).where("is_subscribe = ? and branches.is_approved=?", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
       end
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      if params[:keyword].present?
        @data = Restaurant.joins(:branches).where(country_id: country_id).where("title LIKE (?) and is_subscribe = ? and branches.is_approved=?", "%#{params[:keyword]}%", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
      else
        @data = Restaurant.joins(:branches).where(country_id: country_id).where("is_subscribe = ? and branches.is_approved=?", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
       end
    end
    render layout: "admin_application"
  end

  def restaurant_customer_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @users = if @restaurant.present?
               search_user_list("customer", params[:keyword], @restaurant, params[:searched_country_id], params[:searched_state_id], params[:searched_company_id], params[:searched_restaurant_id], params[:start_date], params[:end_date])
             else
               []
             end

    @users = @users.paginate(page: params[:page], per_page: params[:per_page])
    render layout: "admin_application"
  end

  def customer_wallet
    @user = find_user(decode_token(params[:user_id]))
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @transactions = if @restaurant.present?
                      get_user_transaction(@restaurant, @user)
                    else
                      []
                    end
    render layout: "admin_application"
  end

  def restaurant_reset_password
    @user = find_user(params[:user_id])
    if @user
      @user.auths.first.update(password: params[:new_password])
      responce_json(code: 200, message: "Password changed successfully")
    else
      responce_json(code: 404, message: "Old password doesn't match")
    end
  end

  def chnage_email
    @user = find_user(params[:user_id])
    existing_user = User.find_by(email: params[:email])

    if @user
      if @user.email == params[:email]
        @user.update(email: params[:email], contact: (params[:country_code].to_s + params[:contact].to_s), name: params[:name])
        responce_json(code: 200, message: "Details changed successfully")
      else
        if !existing_user
          @user.update(email: params[:email], contact: (params[:country_code].to_s + params[:contact].to_s), name: params[:name])
          responce_json(code: 200, message: "Details changed successfully")
        else
          responce_json(code: 404, message: "Email already exits!!")
        end
      end
    else
      responce_json(code: 404, message: "User not exits!!")
    end
  end

  def role_user_list
    @users = User.includes(:role, :country).where("role_id IS NOT NULL AND is_approved = 1 OR is_rejected = 1")

    if @admin.class.name == "SuperAdmin"
      @countries = Country.where(id: @users.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      @users = @users.where(users: { country_id: @admin.country_id })
    end

    @roles = Role.where(id: @users.pluck(:role_id).uniq).pluck(:role_name, :id).sort
    @users = @users.filter_users(params[:keyword], params[:searched_country_id], params[:searched_role_id], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @users = @users.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @users.role_user_list_csv, filename: "role_user_list.csv" }
    end
  end

  def add_role_user
    @roles = if session[:admin_user_id]
               Role.all
             else
               Role.where.not(id: 1)
             end
    @user = ""
    render layout: "admin_application"
  end

  def create_role_user
    country_id = if @admin.class.name == "SuperAdmin"
                   params[:country_id]
                 else
                   @admin.class.find(@admin.id)[:country_id]
                 end
    data = User.where(country_id: country_id).where(role_id: 1).count
    if data == 0
      @user = User.create(name: params[:name], email: params[:email], contact: params[:contact], country_code: params[:country_code], role_id: params[:role_id], country_id: country_id, cpr_number: params[:cpr_number])
      if @user.save
        Auth.create_role_user_password(@user, "123456")
        flash[:success] = "User Created Successfully!"
        # redirect_to user_role_user_list_path
        redirect_to user_unapproved_user_list_path
      else
        flash[:error] = @user.errors.full_messages.first.to_s
        redirect_to user_add_role_user_path
        end
    else
      flash[:error] = "Only One Admin user can be created for a given country"
      redirect_to user_add_role_user_path

      end
    end

  def edit_role_user
    @user = User.find(params[:id])
    @roles = if session[:admin_user_id]
               Role.all
             else
               Role.where.not(id: 1)
               end

    render layout: "admin_application"
  end

  def update_role_user
    @user = User.find_by(id: params[:id])
    if @admin.class.name == "SuperAdmin"
      @params = params.require(:user).permit(:name, :email, :contact, :country_code, :role_id, :country_id, :cpr_number)
      if @user.update(name: @params[:name], email: @params[:email], contact: @params[:contact], country_code: @params[:country_code],
                      role_id: @params[:role_id], country_id: @params[:country_id], cpr_number: @params[:cpr_number], is_approved: 0, is_rejected: 0, reject_reason: nil)
        flash[:success] = "User Updated Successfully!"
        redirect_to user_unapproved_user_list_path
      else
        flash[:error] = @user.errors.full_messages.first.to_s
        redirect_to edit_role_user_path(@user.id)
      end
    else
      @params = params.require(:user).permit(:name, :email, :contact, :country_code, :role_id, :cpr_number)
      if @user.update(name: @params[:name], email: @params[:email], contact: @params[:contact], country_code: @params[:country_code],
                      role_id: @params[:role_id], cpr_number: @params[:cpr_number], is_approved: 0, is_rejected: 0, reject_reason: nil)
        flash[:success] = "User Updated Successfully!"
        redirect_to user_unapproved_user_list_path
      else
        flash[:error] = @user.errors.full_messages.first.to_s
        redirect_to edit_role_user_path(@user.id)
      end
  end
  end

  def delete_role_user
    user = User.find_by(id: params[:user_id])
    if user.present?
      user.destroy
      send_json_response("User remove", "success", {})
    else
      send_json_response("User", "not exist", {})
    end
  end

  def unapproved_user_list
    @users = User.includes(:role, :country).where("role_id IS NOT NULL AND is_approved = 0 AND is_rejected = 0")

    if @admin.class.name == "SuperAdmin"
      @countries = Country.where(id: @users.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      @users = @users.where(users: { country_id: @admin.country_id })
    end

    @roles = Role.where(id: @users.pluck(:role_id).uniq).pluck(:role_name, :id).sort
    @users = @users.filter_users(params[:keyword], params[:searched_country_id], params[:searched_role_id], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @users = @users.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      end

      format.csv { send_data @users.unapproved_user_list_csv, filename: "unapproved_user_list.csv" }
    end
  end

  def approve_role_user
    @user = User.find(params[:id])
    @user.update(is_approved: 1, approved_at: Time.zone.now)
    flash[:success] = "User approved Successfully!"
    send_email_on_approve_user(@user.email, @user.name, "123456")
    redirect_to user_unapproved_user_list_path
    # render plain: @user.id
  end

  def reject_role_user
    @user = User.find(params[:id])
    render layout: "admin_application"
    # render plain: @user.id
  end

  def update_role_user_reject
    reject_reason = params.require(:user).permit(:reject_reason)
    @user = User.find_by(id: params[:id])
    if @user.update(reject_reason: reject_reason[:reject_reason], is_rejected: 1, rejected_at: Time.zone.now)
      flash[:success] = "User Updated Successfully!"
      redirect_to user_unapproved_user_list_path
    else
      flash[:error] = @user.errors.full_messages.first.to_s
      redirect_to reject_role_user_path(@user.id)
    end
  end

  def approve_role_user_multiple
    params[:users].each do |privilege|
      @user = User.find(privilege)
      @user.update(is_approved: 1, approved_at: Time.zone.now)
      send_email_on_approve_user(@user.email, @user.name, "123456")
    end
    flash[:success] = "User(s) approved Successfully"
    redirect_to user_unapproved_user_list_path
  end

  def get_currency
    country_code = Country.find_by(id: params[:country_id])
    if country_code.present?
      send_json_response(country_code.currency_code, "success", {})
    else
      send_json_response("N/A", "not exist", {})
    end
  end

  def edit_role_user_password
    @user = User.find(params[:user_id])
    render layout: "admin_application"
  end

  def change_role_user_password
    @user = User.find(params[:user_id])
    auth = @user.auths.first

    if auth
      auth.update(password: params[:password])
      flash[:success] = "Password changed successfully!"
      redirect_to user_role_user_list_path
    else
      flash[:error] = "Old password does not match"
      redirect_to edit_role_user_password_path(user_id: @user.id)
    end
  end

  def mark_influencer
    @user = User.find(params[:user_id])

    if @user.country
      @user.update(influencer: true)
      flash[:success] = "User Successfully marked as Influencer!"
    else
      flash[:error] = "No Country is assigned to User"
    end

    redirect_to request.referer
  end

  def log_off_transporter
    @user = User.find(params[:user_id])

    if @user.status
      @user.update(status: false, is_approved: nil)

      unless @user.delivery_company&.active == false
        last_timing = TransporterTiming.where(user_id: @user.id).last
        last_timing.present? ? last_timing.update(logout_time: DateTime.now) : TransporterTiming.create(user_id: @user.id, logout_time: DateTime.now)
      end

      flash[:success] = "Transporter Logged Off Successfully!"
    else
      @user.update(status: true, is_approved: 0, busy: false)
      TransporterTiming.create(user_id: @user.id, login_time: DateTime.now) unless @user.delivery_company&.active == false
      flash[:success] = "Transporter Logged In Successfully!"
    end

    redirect_to request.referer
  end

  def address_list
    @user = User.find(params[:user_id])
    @selected_user = User.find_by id: params[:selected_user_id]
    @addresses = @user.addresses.includes(coverage_area: :country)
    @countries = @addresses.joins(coverage_area: :country).pluck("countries.name, countries.id").uniq.sort if @addresses.present?
    @addresses = @addresses.where(coverage_areas: { country_id: params[:searched_country_id] }) if params[:searched_country_id].present?

    respond_to do |format|
      format.html { render layout: (params[:is_view_address] == 'true' ? "partner_application" : "admin_application") }
      format.csv { send_data @addresses.user_address_list_csv(@user.name), filename: "user_address_list.csv" }
    end
  end

  def edit_address
    @address = Address.find(params[:address_id])
    @selected_user = User.find_by id: params[:selected_user_id]
    @user = @address.user
    @areas = CoverageArea.where(country_id: @address.coverage_area.country_id).pluck(:area, :id).sort
    render layout: (params[:is_view_address] == 'true' ? "partner_application" : "admin_application")
  end

  def update_address
    address = Address.find(params[:address_id])
    address.update(user_address_params)
    address.update(area: address.coverage_area&.area, contact: params[:address_contact_number])
    flash[:success] = "Address Successfully Updated!"
    redirect_path = params[:is_view_address] == 'true' ? business_customers_list_path(restaurant_id: params[:restaurant_id]) : user_address_list_path(user_id: address.user_id)
    redirect_to redirect_path
  end

  def delete_address
    address = Address.find_by(id: params[:address_id])
    address&.destroy
    flash[:success] = "Address Successfully Deleted!"
    redirect_to request.referer
  end

  def point_list
    @user = User.find(params[:user_id])
    @points = Point.find_user_point(@user, nil, nil, nil)
    @referrals = @user.referrals.select { |r| User.find_by(email: r.email).present? }
    @referrals = @referrals.select { |r| User.find_by(email: r.email).created_at.to_date >= params[:start_date].to_date } if params[:start_date].present?
    @referrals = @referrals.select { |r| User.find_by(email: r.email).created_at.to_date <= params[:end_date].to_date } if params[:end_date].present?

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @user.point_list_csv(@points, @referrals), filename: "user_point_list.csv" }
    end
  end

  def point_details
    @user = User.find(params[:user_id])
    @branch_id = params[:branch_id]
    @branch = Branch.find(@branch_id)
    @points = Point.where(user_id: @user.id, branch_id: @branch_id).order(id: :desc)
    @total_point = branch_available_point(@user.id, @branch_id)
  end

  def check_email_exist
    
    if User.find_by_email(params[:email]).present?
      responce_json(code: 208, message: "Nofitication clear successfully")
    else
      responce_json(code: 200, message: "Nofitication clear successfully")
    end
  end

  private

  def user_address_params
    params.require(:address).permit(:coverage_area_id, :address_type, :address_name, :block, :street, :building, :floor, :apartment_number, :additional_direction, :landline)
  end
end
