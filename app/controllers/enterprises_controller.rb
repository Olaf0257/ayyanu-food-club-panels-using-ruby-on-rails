class EnterprisesController < ApplicationController
  include EnterprisesHelper
  require "roo"
  require "barby/barcode/qr_code"
  require "barby/outputter/svg_outputter"

  before_action :require_admin_logged_in, :check_branch_status, except: [:remove_menu_item, :remove_menu_item_image, :remove_menu_category]


	def information
		@enterprise = Enterprise.new
		@countries =  Country.all
		@selected_country_id = params[:country_id].present? ? decode_token(params[:country_id]) : (session[:country_id].presence || 15)
    session[:country_id] = @selected_country_id
    @countries = Country.where(id: Restaurant.joins(:branches).where(is_signed: true, branches: { is_approved: true }).pluck(:country_id).uniq).where.not(id: @selected_country_id)
    @country_name = Country.find(@selected_country_id).name
    @categories = Category.where.not(icon: nil, icon: "").order_by_title
    @categories = @categories.where.not(title: "Party") if Point.sellable_restaurant_wise_points(@selected_country_id).empty?
    @areas = CoverageArea.active_areas.where(country_id: @selected_country_id)
    @restaurants = Restaurant.joins(:branches).where(country_id: @selected_country_id, is_signed: true, branches: { is_approved: true }).where.not(title: "").distinct.order(:title).first(7)
	end


	def create
    restaurant = add_enterprise_request(enterprise_params[:enterprise_name], enterprise_params[:restaurant_id], enterprise_params[:person_name], enterprise_params[:contact_number], enterprise_params[:role], enterprise_params[:email], enterprise_params[:coverage_area_id], enterprise_params[:cuisine], enterprise_params[:cr_number], enterprise_params[:bank_name], enterprise_params[:bank_account], enterprise_params[:images], enterprise_params[:signature], enterprise_params[:cpr_number], enterprise_params[:owner_name], enterprise_params[:nationality], enterprise_params[:submitted_by], enterprise_params[:delivery_status], enterprise_params[:branch_no], enterprise_params[:mother_company_name], enterprise_params[:serving], enterprise_params[:block], enterprise_params[:road_number], enterprise_params[:building], enterprise_params[:unit_number], enterprise_params[:floor], enterprise_params[:other_name], enterprise_params[:other_role], enterprise_params[:other_email], enterprise_params[:country_id])
    if restaurant
      @admin = get_admin_user
      # msg = "#{restaurant.enterprise_name} restaurant has request to join Food Club"
      # type = "request_new_restaurant"
      # send_notification_releted_menu(msg, type, "", @admin, restaurant.id)
      # responce_json(code: 200, message: "Your request submitted successfully.")
      flash[:success] = "Request Submitted Successfully!"
      redirect_to '/enterprise/information'
    else
      flash[:error] = "Something went wrong"
      redirect_to '/enterprise/information'
    end
  end

  def requested_enterprise
    # @admin = User.find_by_email("m.hadidi@foodclubco.com")
    if @admin.class.name == "SuperAdmin" || true
      @newRestaurant = Enterprise.requested_list
      @countries = Country.where(id: @newRestaurant.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @newRestaurant = Enterprise.where(country_id: country_id).requested_list
      @countries = Country.where(id: country_id).pluck(:name, :id).sort
    end

    @newRestaurant = @newRestaurant.search_by_name_and_country(params[:keyword], params[:searched_country_id])
    @newRestaurant = @newRestaurant.where("DATE(new_restaurants.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @newRestaurant = @newRestaurant.where("DATE(new_restaurants.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @newRestaurant = @newRestaurant.order(id: :desc)

    respond_to do |format|
      format.html do
        @newRestaurant = @newRestaurant.paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      # format.csv { send_data @newRestaurant.requested_restaurant_list_csv, filename: "requested_restaurant_list.csv" }
    end
  end

  def enterprise_request_details
    @req_restaurant = get_request_restaurant(params[:id])
    if @req_restaurant
      @closed_branches = 0
      @open_branches = 0
      @busy_branches = 0
      # @images = @req_restaurant.new_restaurant_images rescue nil
    else
      flash[:error] = "Data not exists"
    end
    render layout: "admin_application"
  end

  def approve_enterprise
    begin
      req_restaurant = get_request_restaurant(params[:req_restaurant_id])
      email = user_email_and_role(req_restaurant.email, "business")
      if req_restaurant && !req_restaurant.is_rejected && !req_restaurant.is_approved && !email
        approveRestaurant = update_restaurant_data(req_restaurant)
        responce_json(code: 200, message: "Enterprise Approved!")
      else
        data = req_restaurant.update(is_approved: true)

        if req_restaurant.restaurant.present?
          req_restaurant.restaurant.update(user_id: email.id, country_id: req_restaurant.country_id)
        else
          # restaurant = Restaurant.new(title: req_restaurant.restaurant_name, user_id: email.id, is_signed: false, country_id: req_restaurant.country_id)

          # if restaurant.save
          #   restaurant.branches.create(address: "", city: req_restaurant.coverage_area&.area.to_s, country: req_restaurant.country&.name.to_s, tax_percentage: 5, daily_timing: "")
          # end
        end
        # send_email_on_restaurant_owner(req_restaurant.email, email.name, nil)
        responce_json(code: 200, message: "Enterprise approved")
      end
    rescue => e
      responce_json(code: 500, message: e.message)
    end
  end

  def enterprise_view
    @restaurant = get_restaurant_data(decode_token(params[:id]))
    branches = @restaurant.branches.pluck(:id)
    # area = BranchCoverageArea.where(:branch_id=>branches)
    @closed_branches = @restaurant.branches.where(is_closed: true).count # area.where(:is_closed=>true).count
    @open_branches = @restaurant.branches.where(is_closed: false, is_busy: false).count
    @busy_branches = @restaurant.branches.where(is_busy: true).count
    @taotal_sales  = get_restaurant_sales(@restaurant.branches.pluck(:id))
    # @order_reviews = get_restaurant_order_reviews(@restaurant.id, params[:page], params[:per_page])
    @ratings = get_restaurant_ratings(@restaurant.branches.pluck(:id), params[:start_date], params[:end_date])
    @start_date = params[:start_date].presence || "NA"
    @end_date = params[:end_date].presence || "NA"

    respond_to do |format|
      format.html do
        @ratings = @ratings.paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @ratings.restaurant_rating_csv(@restaurant.title, @start_date, @end_date), filename: "Restaurant_Ratings_List.csv" }
    end
  end

  def reject_enterprise_request
    req_restaurant = get_request_restaurant(params[:req_restaurant_id])

    if req_restaurant && !req_restaurant.is_rejected && !req_restaurant.is_approved
      reject_restaurant = update_restaurant_reject_data(req_restaurant, params[:reject_reason])
      flash[:error] = "Enterprise rejected."
      redirect_back(fallback_location: restaurant_list_path)
    else
      flash[:error] = "Invalid request!!"
      redirect_back(fallback_location: restaurant_list_path)
    end
  end

  def all_enterprise
    @restaurants = Enterprise.where(is_approved: true).order("updated_at desc")
    @restaurants = @restaurants.where(country_id: @admin.country_id) unless helpers.is_super_admin?(@admin)
    @countries = Country.where(id: @restaurants.pluck(:country_id).uniq).pluck(:name, :id).sort
    @restaurants = @restaurants.where(country_id: params[:searched_country_id]) if params[:searched_country_id].present?
    @restaurants = @restaurants.where("restaurants.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @restaurants = @restaurants.where("DATE(restaurants.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @restaurants = @restaurants.where("DATE(restaurants.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @restaurants = @restaurants.where(is_signed: (params[:status] == "Enabled")) if params[:status].present?

    respond_to do |format|
      format.html do
        @restaurants = @restaurants.includes(:country, :user, :enterprise_document, branches: :branch_coverage_areas).paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @restaurants.includes(:country).all_restaurant_list_csv, filename: "all_restaurant_list.csv" }
    end

    
  end

  def rejected_enterprise
    if @admin.class.name == "SuperAdmin"
      @newRestaurant = Enterprise.rejected_list
      @countries = Country.where(id: @newRestaurant.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @newRestaurant = Enterprise.where(country_id: country_id).rejected_list
      @countries = Country.where(id: country_id).pluck(:name, :id).sort
    end

    @newRestaurant = @newRestaurant.search_by_name_and_country(params[:keyword], params[:searched_country_id])
    @newRestaurant = @newRestaurant.where("new_restaurants.rejected_at IS NOT NULL AND DATE(new_restaurants.rejected_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @newRestaurant = @newRestaurant.where("new_restaurants.rejected_at IS NOT NULL AND DATE(new_restaurants.rejected_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @newRestaurant = @newRestaurant.order(id: :desc)

    respond_to do |format|
      format.html do
        @newRestaurant = @newRestaurant.paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @newRestaurant.rejected_restaurant_list_csv, filename: "rejected_restaurant_list.csv" }
    end
  end

  def delete_enterprise
    restaurant = Enterprise.find_by(id: params[:id])

    if restaurant
      restaurant.delete
      # render json: { code: 200 }
      flash[:success] = "Enterprise deleted successfully!"
    else
      flash[:erorr] = "Enterprise does not exists"
      # render json: { code: 404 }
    end
    redirect_to request.referer
  end

  def edit_request_enterprise
    @req_restaurant = get_request_restaurant(params[:id])
    render layout: "admin_application"
  end

  def update_request_enterprise
    @req_restaurant = get_request_restaurant(params[:req_restaurant_id])
    email = get_email_details(params[:email])
    if @req_restaurant.present? && (params[:email] == @req_restaurant.email)
      @req_restaurant.update(enterprise_name: params[:restaurant_name], owner_name: params[:owner_name], email: params[:email].downcase, contact_number: params[:full_phone], cpr_number: params[:cpr_number], enterprise_id: params[:enterprise_id], branch_no: params[:branch_no])
      flash[:success] = "successfully updated"
    elsif !email
      @req_restaurant.update(restaurant_name: params[:restaurant_name], owner_name: params[:owner_name], email: params[:email].downcase, contact_number: params[:full_phone], cpr_number: params[:cpr_number], restaurant_id: params[:restaurant_id], branch_no: params[:branch_no])
    else
      flash[:error] = "Email already exists. Please choose a different email!!"
    end
    if @req_restaurant.is_approved
      redirect_to enterprise_list_path
    elsif @req_restaurant.is_rejected
      redirect_to rejected_enterprise_path
    else
      redirect_to requested_enterprise_enterprises_path
    end
  end

  def get_states
    @states = CoverageArea.where(country_id: params[:country_id]).order(area: "ASC")
  end

  def login_as_enterprise_owner
    restaurant = Enterprise.find(params[:restaurant_id])
    user = restaurant.user
    auth = user&.auths&.find_by(role: "business")
    Rails.logger.info "user_id: #{user.id}"
    Rails.logger.info "enterprise: #{restaurant.id}"
    if user && auth
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:partner_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully as " + user.name
      # redirect_to business_partner_dashboard_path(restaurant_id: encode_token(restaurant.id))
      redirect_to business_enterprise_dashboard_path(enterprise_id: encode_token(user.enterprise.id))
    else
      Rails.logger.info "else condition executed"
      flash[:error] = "User not found"
      redirect_to root_path
    end
  end

  private

  def validate_request
    role = %w[business manager other]
    validateRole = role.include? params[:role]
    unless params[:restaurant_name].present? && params[:person_name].present? && params[:contact_number].present? && validateRole && params[:email].present? && params[:area].present? && params[:cuisine].present? && params[:images].present?
      responce_json(code: 422, message: "Please enter required parameter!!")
    end
  end

  def enterprise_params
    params.require(:enterprise).permit(:name, :person_name, :contact_number, :role, :email, :coverage_area, :is_approved, :is_rejected, :rejected_reason, :cr_number, :bank_name, :bank_account, :cpr_number, :owner_name, :nationality, :submitted_by, :delivery_status, :branch_no, :enterprise_name, :road_number, :building, :unit_number, :floor, :other_user_email, :other_user_name, :other_user_role, :other_user_role, :block, :restaurant_id, :country_id, :rejected_at, :coverage_area_id, :area)
  end

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
  rescue ActiveRecord::StatementInvalid => e
  end

end