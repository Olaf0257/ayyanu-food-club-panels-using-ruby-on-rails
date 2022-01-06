class Business::UsersController < ApplicationController
  before_action :authenticate_business, except: [:update_branches]

  def index
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant && (@user.auths.first.role == "business")
      @branch = restaurant.branches.find_by(id: params[:branch])
      @transporters = filter_data(restaurant, @branch, params[:keyword], params[:vehicle_type])
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    elsif @user.auths.first.role == "manager"
      @branch = @user.manager_branches.find_by(id: params[:branch])
      @restaurants = @user.restaurants
      @transporters = filter_data("", @branch, params[:keyword], params[:vehicle_type])
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    else

      redirect_to_root
    end
  end

  def change_branches
    @manager = User.find(params[:id])
    @restaurant_id = params[:restaurant_id]
    @branches = @manager.branch_managers.first.branch.restaurant.branches
  end

  def update_branches
    @manager = User.find(params[:manager_id])
    @branches = Branch.where(id: params[:branch_id])

    if @branches.present?
      @manager.branch_managers.destroy_all

      @branches.each do |branch|
        BranchManager.create_branch_managers(@manager, branch)
      end
    end

    flash[:success] = "Branches Updated Successfully!"
    redirect_to business_managers_path(restaurant_id: params[:restaurant_id])
  end

  def all_managers
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant && (@user.auths.first.role == "business")
      @branch = restaurant.branches.find_by(id: params[:branch])
      @managers = filter_managers(restaurant, @branch, params[:keyword]).includes(:manager_branches).distinct
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches.paginate(page: params[:page], per_page: params[:per_page])
      # redirect_to business_managers_path(restaurant_id: encode_token(restaurant.id))
      render layout: "partner_application"
    elsif @user.auths.first.role == "manager"
      @restaurants = @user.restaurants
      @branch = @user.manager_branches.find_by(id: params[:branch])
      @managers = filter_managers("", @branch, params[:keyword]).includes(:manager_branches).distinct
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches.paginate(page: params[:page], per_page: params[:per_page])
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end

  def all_kitchen_managers
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant && (@user.auths.first.role == "business")
      @branch = restaurant.branches.find_by(id: params[:branch])
      @managers = filter_kitchen_managers(restaurant, @branch, params[:keyword])
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches.paginate(page: params[:page], per_page: params[:per_page])
      render layout: "partner_application"
    elsif @user.auths.first.role == "manager"
      @restaurants = @user.restaurants
      @branch = @user.manager_branches.find_by(id: params[:branch])
      @managers = filter_kitchen_managers("", @branch, params[:keyword])
      @branches = @user.manager_branches.paginate(page: params[:page], per_page: params[:per_page])
      render layout: "partner_application"
    else
      redirect_to_root
      end
  end

  def add_transporter
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant && (@user.auths.first.role == "business")
      @branches = restaurant.branches
      render layout: "partner_application"
    elsif @user.auths.first.role == "manager"
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    else
      redirect_to_root
    end
  end

  def create
    restaurant = params[:restaurant_id]

    if params[:role] == "manager"
      branch = get_restaurant_branch(params[:branch_id].first)
    else
      branch = get_restaurant_branch(params[:branch_id])
    end

    user = params[:role] == "transporter" ? get_user_cpr_number(params[:cpr_number]) : user_email(params[:email])

    if ((params[:role] == "transporter") && params[:cpr_number].present? && params[:password].present?) || ((params[:role] == "manager") && params[:email].present? && params[:password].present?) || ((params[:role] == "kitchen_manager") && params[:email].present? && params[:password].present?)
      if !user && branch
        if params[:role] == "manager"
          create_employee(params[:branch_id], params[:firstname], params[:role] == "transporter" ? params[:cpr_number] + "@gmail.com" : params[:email], params[:role], params[:contact], params[:country_code], params[:password], params[:image], params[:cpr_number], params[:vehicle_type])
        else
          create_employee(branch, params[:firstname], params[:role] == "transporter" ? params[:cpr_number] + "@gmail.com" : params[:email], params[:role], params[:contact], params[:country_code], params[:password], params[:image], params[:cpr_number], params[:vehicle_type])
        end

        flash[:success] = (params[:role] == "transporter" ? "Transporter created successfully" : params[:role] == "kitchen_manager" ? "Kitchen Manager created successfully" : "Manager created successfully").to_s

        if params[:role] == "transporter"
          redirect_to business_transporters_path(restaurant_id: restaurant)
        elsif params[:role] == "kitchen_manager"
          redirect_to business_kitchen_managers_path(restaurant_id: params[:restaurant_id])
        else
          redirect_to business_managers_path(restaurant_id: restaurant)
        end
      else
        flash[:error] = (params[:role] == "transporter" ? "Cpr Number already exists " : "Email already exists").to_s
        redirect_to business_add_transporter_path(restaurant_id: restaurant, type: params[:role])
      end
    else
      flash[:error] = "Required parameter is missing!!"
      redirect_to business_add_transporter_path(restaurant_id: restaurant, type: params[:role])
    end
  end

  def update
    user = find_user(params[:user_id])
    restaurant = params[:restaurant_id]

    if user
      update_employee(user, params[:firstname], params[:role], params[:contact].strip, params[:country_code], params[:image], params[:vehicle_type])
      flash[:success] = (params[:role].casecmp("transporter").zero? ? "Transporter details update successfully" : "Manager details update successfully").to_s
      if params[:role].casecmp("transporter").zero?
        redirect_to business_transporters_path(restaurant_id: restaurant)
      elsif params[:role] == "Kitchen Manager"
        redirect_to business_kitchen_managers_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_managers_path(restaurant_id: restaurant)
      end
    else
      flash[:error] = "User does not exists"
      redirect_to business_branchshow_path(params[:branch_id])
    end
  end

  def reset_password
    @user = find_user(params[:user_id])
    auth = %w[transporter kitchen_manager manager].include?(params[:role]) ? get_user_auth(@user, params[:role]) : get_user_auth(@user, @user.auths.first.role)

    if %w[transporter kitchen_manager manager].include?(params[:role])
      auth.update(password: params[:new_password])
      responce_json(code: 200, message: "Password changed successfully")
    elsif auth.valid_password?(params[:old_password])
      auth.update(password: params[:new_password])
      @user.auths.first.role == "business" ? responce_json(code: 200, message: "Password change successfully", user: business_user_login_json(@user).merge(api_key: request.headers["accessToken"])) : responce_json(code: 200, message: "Password change successfully", user: user_login_json(@user).merge(api_key: request.headers["accessToken"]))
    else
      responce_json(code: 404, message: "Old password doesn't match")
    end
  end

  def business_edit
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    render layout: "partner_application"
  end

  def track_drivers
    if params[:restaurant_id].present? && @user.auths.first.role == "business"
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    elsif @user.auths.first.role == "manager"
      @restaurant = @user.manager_branches.first.restaurant
    end

    busy_transporter_ids = Order.where(branch_id: @restaurant.branches.pluck(:id), is_accepted: true, is_delivered: false, is_cancelled: false).where("date(orders.created_at) = ?", Date.today).pluck(:transporter_id).uniq
    @drivers = User.joins(branch_transports: :branch).where(branches: { restaurant_id: @restaurant.id }).available_drivers
    @driver_details = @drivers.map { |d| [d.name, d.latitude.to_f, d.longitude.to_f, busy_transporter_ids.include?(d.id), d.vehicle_type.to_s] }
    render layout: "partner_application"
  end

  def remove_employee
    emp = find_user(params[:id])
    if emp
      emp.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "User does not exists"
      render json: { code: 404 }
    end
  end
end
