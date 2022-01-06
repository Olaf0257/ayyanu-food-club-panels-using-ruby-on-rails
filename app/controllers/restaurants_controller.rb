class RestaurantsController < ApplicationController
  require "roo"
  require "barby/barcode/qr_code"
  require "barby/outputter/svg_outputter"

  before_action :require_admin_logged_in, :check_branch_status, except: [:remove_menu_item, :remove_menu_item_image, :remove_menu_category]

  def branch_qr_code
    @branch = Branch.find(decode_token(params[:branch_id]))
    @area_id = CoverageArea.find_by(area: @branch.city, country_id: @branch.restaurant.country_id)&.id
    @barcode_string = @area_id ? "https://mysterious-beyond-87234.herokuapp.com/customer/restaurant/#{params[:branch_id]}/details?area_id=#{encode_token(@area_id)}&scan_branch=true" : ""
    @barcode = Barby::QrCode.new(@barcode_string, level: :q, size: 10).to_svg(margin: 0)
    render layout: false
  end

  def all_restaurant
    @restaurants = Restaurant.all
    @restaurants = @restaurants.where(country_id: @admin.country_id) unless helpers.is_super_admin?(@admin)
    @countries = Country.where(id: @restaurants.pluck(:country_id).uniq).pluck(:name, :id).sort
    @restaurants = @restaurants.where(country_id: params[:searched_country_id]) if params[:searched_country_id].present?
    @restaurants = @restaurants.where("restaurants.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @restaurants = @restaurants.where("DATE(restaurants.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @restaurants = @restaurants.where("DATE(restaurants.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @restaurants = @restaurants.where(is_signed: (params[:status] == "Enabled")) if params[:status].present?

    respond_to do |format|
      format.html do
        @restaurants = @restaurants.includes(:country, :user, :restaurant_document, branches: :branch_coverage_areas).paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @restaurants.includes(:country).all_restaurant_list_csv, filename: "all_restaurant_list.csv" }
    end
  end

  def login_as_restaurant_owner
    restaurant = Restaurant.find(params[:restaurant_id])
    user = restaurant.user
    auth = user&.auths&.find_by(role: "business")

    if user && auth
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      session[:partner_user_id] = server_session.server_token
      flash[:success] = "Logged In Successfully as " + user.name
      redirect_to business_partner_dashboard_path(restaurant_id: encode_token(restaurant.id))
    else
      flash[:error] = "User not found"
      redirect_to root_path
    end
  end

  def restaurant_view
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

  def branch_view
    @restaurant = get_restaurant_data(decode_token(params[:id]))
    @branches = @restaurant.branches

    render layout: "admin_application"
  end

  def download_csv
    @branch = get_branch_data(params[:id])
    @menu_categories = branch_menu_category(@branch, "", "")
    @menu_items = branch_menu_item(@branch, @menu_categories, "", "")
    @addon_categories = branch_addon_category(@branch, "", "")
    @item_cat_addons = branch_addon_category(@branch, "", "")

    respond_to do |format|
      format.xls {
        response.headers[ 'Content-Disposition' ] = "attachment; filename=Menu-List-#{ @branch.city }-#{ @branch.restaurant.title }.xls"
      }
    end
  end

  def restaurant_branch_menu
    @branch = get_branch_data(decode_token(params[:id]))

    if @branch
      #@menu = get_business_branch_menu_list(@user, nil, @branch, "", "", "", "")
      @menu_categories = branch_menu_category(@branch, params[:keyword], params[:category])
      @menu_items = branch_menu_item(@branch, @menu_categories, params[:keyword], params[:category])
      @addon_categories = branch_addon_category(@branch, params[:keyword], params[:category])
      @daily_dishes = @branch.menu_categories.find_by(category_title: "Daily Dishes")
      @catering = @branch.menu_categories.find_by(category_title: "Catering")
      @item_cat_addons = branch_addon_category(@branch, params[:keyword], params[:category])
      render layout: "admin_application"
    else
      flash[:erorr] = "Branch does not exists!!"
      redirect_back(fallback_location: restaurant_list_path)
    end
  end

  def admin_branch_coverage_area
    @coverage_areas = CoverageArea.all.pluck(:area)
    @branch = get_branch_data(decode_token(params[:id]))
    @branches = @branch.branch_coverage_areas
    @branches = @branches.joins(:coverage_area).where("coverage_areas.area LIKE ?", "%#{params[:keyword]}%").uniq if params[:keyword].present?

    if @branch
      @branches = @branches.paginate(page: params[:page], per_page: params[:per_page])
      render layout: "admin_application"
    else
      flash[:erorr] = "Branch does not exists!!"
      redirect_back(fallback_location: restaurant_list_path)
    end
  end

  def admin_delete_branch_coverage_area
    @branch_coverage_area = BranchCoverageArea.find(params[:id])
    @branch_coverage_area.destroy
    flash[:success] = "Branch Coverage Area Successfully Deleted!"
    redirect_to request.referer
  end

  def admin_branch_coverage_area_bulk_action
    if params[:coverage_area_ids].present?
      params[:coverage_area_ids].each do |coverage_id|
        branch_coverage_area = BranchCoverageArea.find_by(id: coverage_id)
        branch_coverage_area&.destroy
      end

      flash[:success] = "Coverage Areas Deleted Successfully!"
    else
      flash[:error] = "Please Select a Coverage Area"
    end

    redirect_to request.referer
  end

  def add_new_menu_category
    @branch = get_branch_data(decode_token(params[:branch_id]))
    render layout: "admin_application"
  end

  def add_menu_category
    menu_category = find_menu_category_branch(params[:category_title], params[:branch_id])

    if !menu_category
      menu_category = new_menu_category(params[:category_title], params[:category_title_ar], params[:branch_id], true, params[:available])
      menu_category.update(start_date: params[:start_date]&.strip, end_date: params[:end_date]&.strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"))
      flash[:success] = "Menu category added successfully"
    else
      flash[:error] = "Menu category already exists"
    end

    redirect_to admin_branch_menu_items_path(encode_token(params[:branch_id]))
  end

  def edit_menu_category
    menu_category = get_menu_category(params[:category_id])

    if menu_category
      menu_category.update(start_date: params[:start_date]&.strip, end_date: params[:end_date]&.strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"), include_in_pos: params[:include_in_pos], include_in_app: params[:include_in_app])
      is_update_menu_category(menu_category, params[:category_title].strip, params[:category_title_ar].strip, menu_category.branch.id, params[:category_priority], params[:available])
      flash[:success] = "Successfully Updated!"
    else
      flash[:error] = "Menu category already exists"
    end

    redirect_to session.delete(:return_to)
  end

  def update_menu_category
    session[:return_to] = request.referer
    @menu_category = get_menu_category(decode_token(params[:category_id]))

    render layout: "admin_application"
  end

  def new_menu_item
    @branch = get_branch(decode_token(params[:branch_id]))
    @item_cat_addons = @branch.item_addon_categories
    @menu_category = find_menu_category_by_branch(@branch.id)
    render layout: "admin_application"
  end

  def add_menu_item
    item = get_menu_item_name_catId(params[:item_name], params[:menu_category_id])

    if !item
      status = is_new_menu_item(params[:item_name], params[:price_per_item], params[:image], params[:item_description], params[:menu_category_id], params[:is_available], params[:item_name_ar], params[:item_description_ar], params[:calorie], true, params[:addon_category_id], params[:dish_date], params[:far_menu], params[:include_in_pos], params[:include_in_app])
      @branch_id = MenuCategory.find(params[:menu_category_id]).branch_id
      flash[:success] = "Menu Item added sucessfully"
      redirect_to admin_branch_menu_items_path(encode_token(@branch_id))
    else
      flash[:error] = "Already exists"
      redirect_back(fallback_location: "all_restaurant_path")
    end
  end

  def menu_category_item_list
    @category = MenuCategory.find(decode_token(params[:menu_category_id]))
    @items = @category.menu_items
    @items = @items.search_by_name(params[:keyword]) if params[:keyword].present?
    @items = @items.paginate(page: params[:page], per_page: 50)
    @restaurant_id = @category.branch.restaurant_id
    render layout: "admin_application"
  end

  def update_menu_item
    session[:return_to] = request.referer
    @branch = get_branch(decode_token(params[:branch_id]))
    @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    @menu_category = find_menu_category_by_branch(decode_token(params[:branch_id]))
    @addon_category = @menu_item.item_addon_categories.pluck(:id)
    @item_cat_addons = @branch.item_addon_categories
    @date = @menu_item.menu_item_dates.where("DATE(menu_date) >= (?)", Date.today).order("menu_date ASC").pluck(:menu_date)
    @allDate = @date.map { |d| d.strftime("%Y-%m-%d") }.join(", ")
    render layout: "admin_application"
  end

  def edit_menu_item
    item = get_menu_id_catId(params[:menu_item_id], params[:menu_category_id])

    if item
      status = is_update_menu_item(item, params[:item_name], params[:price_per_item], params[:image], params[:item_description], params[:menu_category_id], params[:is_available], params[:item_name_ar], params[:item_description_ar], false, params[:calorie], params[:dish_date], params[:addon_category_id], params[:far_menu], params[:include_in_pos], params[:include_in_app])
      item.update(approve: true) if item.saved_changes.keys.reject { |k| ["approve", "updated_at"].include?(k) }.empty?
      flash[:success] = "Menu Item updated successfully"
    else
      flash[:error] = "Item not exists"
    end

    redirect_to session.delete(:return_to)
  end

  def remove_menu_item
    item = get_menu_item(params[:id])
    if item
      item.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Item does not exists"
      render json: { code: 404 }
    end
  end

  def remove_menu_item_image
    item = MenuItem.find_by(id: params[:id])

    if item
      item.update(item_image: nil)
      render json: { code: 200 }
    else
      flash[:erorr] = "Item does not exists"
      render json: { code: 404 }
    end
  end

  def remove_menu_category
    category = get_menu_category(params[:id])
    if category
      category.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Category does not exists"
      render json: { code: 404 }
    end
  end

  def item_addon_list
    @branch = get_branch(decode_token(params[:branch_id]))
    @cat_addons = ItemAddonCategory.all
    @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    @item_cat_addons = ItemAddonCategory.where(menu_item_id: decode_token(params[:menu_item_id]))
    render layout: "admin_application"
  end

  def change_restaurant_signed_state
    restaurant = get_restaurant(params[:restaurant_id])
    if restaurant
      restaurant.update(is_signed: params[:status])
      flash[:success] = "Restaurant status update"
    end
    respond_to do |format|
      format.js { render "all_restaurant" }
    end
  end

  def approved_branch
    branch = get_branch(params[:branch_id])

    if branch
      status = branch.update(is_approved: params[:status])
      branch.branch_coverage_areas.update_all(is_busy: params[:busy])
      Branch.set_subscribe_branch(branch, params[:status]) if status
    end

    # flash[:success]= branch.is_approved ? "Branch approved successfully" : "Branch diapproved successfully"
    respond_to do |format|
      format.js { render "branch_view" }
    end
  end

  def requested_restaurant
    if @admin.class.name == "SuperAdmin"
      @newRestaurant = NewRestaurant.requested_list
      @countries = Country.where(id: @newRestaurant.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @newRestaurant = NewRestaurant.where(country_id: country_id).requested_list
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

      format.csv { send_data @newRestaurant.requested_restaurant_list_csv, filename: "requested_restaurant_list.csv" }
    end
  end

  def rejected_restaurant
    if @admin.class.name == "SuperAdmin"
      @newRestaurant = NewRestaurant.rejected_list
      @countries = Country.where(id: @newRestaurant.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @newRestaurant = NewRestaurant.where(country_id: country_id).rejected_list
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

  def pending_update_request
    if @admin.class.name =='SuperAdmin'
      @restaurants = Restaurant.pending_name_update_request_list
      @countries = Country.where(id: @restaurants.pluck(:country_id).uniq).pluck(:name, :id).sort
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @restaurants = Restaurant.where(country_id: country_id).pending_name_update_request_list
      @countries = Country.where(id: country_id).pluck(:name, :id).sort
    end

    @restaurants = @restaurants.find_pending_update_request_list(params[:keyword], params[:searched_country_id], params[:status])
    @restaurants = @restaurants.where("restaurants.name_change_requested_on IS NOT NULL AND DATE(restaurants.name_change_requested_on) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @restaurants = @restaurants.where("restaurants.name_change_requested_on IS NOT NULL AND DATE(restaurants.name_change_requested_on) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @restaurants = @restaurants.order(id: :desc)

    respond_to do |format|
      format.html do
        @restaurants = @restaurants.paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @restaurants.name_approval_restaurant_list_csv, filename: "name_approval_restaurant_list.csv" }
    end
  end

  def approve_name_change
    restaurant = Restaurant.find_by(id: params[:id])

    if restaurant
      restaurant.update(title: restaurant.temp_title, title_ar: restaurant.temp_title_ar, approved: true, rejected: false)
      msg = restaurant.title + " restaurant name change approved by admin"
      notify_to_business("", restaurant, get_admin_user, msg, "Approved", "Approved")
      render json: { code: 200 }
    else
      flash[:erorr] = "Restaurant does not exist"
      render json: { code: 404 }
    end
  end

  def reject_name_change
    restaurant = Restaurant.find_by(id: params[:id])

    if restaurant
      restaurant.update(rejected: true, approved: false)
      msg = restaurant.title + " restaurant name change rejected by admin"
      notify_to_business("", restaurant, get_admin_user, msg, "Rejected", "Rejected")
      render json: { code: 200 }
    else
      flash[:erorr] = "Restaurant does not exist"
      render json: { code: 404 }
    end
  end

  def delete_restaurant
    restaurant = NewRestaurant.find_by(id: params[:id])

    if restaurant
      restaurant.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Restaurant does not exists"
      render json: { code: 404 }
    end
  end

  def restaurant_request_details
    @req_restaurant = get_request_restaurant(params[:id])
    if @req_restaurant
      @closed_branches = 0
      @open_branches = 0
      @busy_branches = 0
      @images = @req_restaurant.new_restaurant_images
    else
      flash[:error] = "Data not exists"
    end
    render layout: "admin_application"
  end

  def approve_restaurant
    req_restaurant = get_request_restaurant(params[:req_restaurant_id])
    email = user_email_and_role(req_restaurant.email, "business")
    if req_restaurant && !req_restaurant.is_rejected && !req_restaurant.is_approved && !email
      approveRestaurant = update_restaurant_data(req_restaurant)
      responce_json(code: 200, message: "Restaurant approved")
    else
      data = req_restaurant.update(is_approved: true)

      if req_restaurant.restaurant.present?
        req_restaurant.restaurant.update(user_id: email.id, country_id: req_restaurant.country_id)
      else
        restaurant = Restaurant.new(title: req_restaurant.restaurant_name, user_id: email.id, is_signed: false, country_id: req_restaurant.country_id)

        if restaurant.save
          restaurant.branches.create(address: "", city: req_restaurant.coverage_area&.area.to_s, country: req_restaurant.country&.name.to_s, tax_percentage: 5, daily_timing: "")
        end
      end

      send_email_on_restaurant_owner(req_restaurant.email, email.name, nil)
      responce_json(code: 200, message: "Restaurant approved")
    end
  end

  def reject_restaurant_request
    req_restaurant = get_request_restaurant(params[:req_restaurant_id])

    if req_restaurant && !req_restaurant.is_rejected && !req_restaurant.is_approved
      reject_restaurant = update_restaurant_reject_data(req_restaurant, params[:reject_reason])
      flash[:error] = "Restaurant rejected."
      redirect_back(fallback_location: restaurant_list_path)
    else
      flash[:error] = "Invalid request!!"
      redirect_back(fallback_location: restaurant_list_path)
    end
  end

  def download_restaurant_doc
    doc = get_restaurant_doc(params[:req_restaurant_img_id])
    if doc
      download_doc = get_download_link(doc)
      responce_json(code: 200, message: "Restaurant approved")
    else
      responce_json(code: 422, message: "Invalid Request")
    end
  end

  def restaurant_payment_invoice
    @restaurant = get_restaurant(params[:id])
    if @restaurant
      orders = Order.joins(branch: :restaurant).where("order_type = ? and restaurant_id = ?", "prepaid", @restaurant.id)
      baseAmount = orders.pluck(:total_amount).sum
      reportFee = Servicefee.first
      fee = @restaurant.is_subscribe ? reportFee.report_subscribe_fee : 0.000
      branch_fee = helpers.number_with_precision(@restaurant.branches.where(is_approved: true).count * reportFee.branch_subscription_fee, precision: 3)
      total_amount = baseAmount - (fee + (@restaurant.branches.count * reportFee.branch_subscription_fee))
      @invoice = { id: @restaurant.id, restaurant_title: @restaurant.title, amount: helpers.number_with_precision(baseAmount, precision: 3), fee: helpers.number_with_precision(fee, precision: 3), vat: 0.000, total_amount: total_amount, branch_fee: branch_fee }
      render layout: "admin_application"
    end
  end

  def add_addon_category
    @branch = get_branch(decode_token(params[:branch_id]))
    render layout: "admin_application"
  end

  def new_addon_category
    @branch = Branch.find(params[:branch_id])
    category = get_addon_category(params[:addon_category_name], @menu_item&.id)

    unless category
      addon_category = addon_category_add(@branch, params[:addon_category_name], params[:addon_category_name_ar], params[:min_selected_quantity].presence || 0, params[:max_selected_quantity].presence || 0, true, params[:available])
      flash[:success] = "Addon category added successfully."
    else
      flash[:error] = "Addon category already exists"
    end

    # redirect_to item_addon_list_path(menu_item_id: encode_token(@menu_item.id), branch_id: encode_token(@menu_item.menu_category.branch.id))
    redirect_to admin_branch_menu_items_path(encode_token(@branch.id))
  end

  def addon_item
    @branch = get_branch(decode_token(params[:branch_id]))
    @addon_categories = @branch.item_addon_categories
    render layout: "admin_application"
  end

  def new_addon_item
    category = get_addon_category_through_id(params[:addon_category_id])

    if category
      addon = add_new_addon_item(category, params[:item_name], params[:price_per_item], params[:item_name_ar], true, params[:available], params[:include_in_pos], params[:include_in_app])
    else
      flash[:error] = "Addon category not exists"
    end

    redirect_to admin_branch_menu_items_path(encode_token(category.branch_id))
  end

  def edit_addon_item
    session[:return_to] = request.referer
    @addon_item = get_addon_item(decode_token(params[:addon_item_id]))
    @branch = get_branch(decode_token(params[:branch_id]))
    @addon_categories = @branch.item_addon_categories
    render layout: "admin_application"
  end

  def update_addon_item
    addon_item = get_addon_item(params[:addon_item_id])
    @branch = get_branch(params[:branch_id])

    if addon_item
      addonItem = update_addon(addon_item, params[:item_name], params[:price_per_item], params[:addon_category_id], params[:item_name_ar], false, params[:available], params[:include_in_pos], params[:include_in_app])
      flash[:success] = "Updated successfully"
    else
      flash[:error] = "Addon item not exists"
    end

    redirect_to session.delete(:return_to)
  end

  def remove_addon_item
    addon_item = get_addon_item(params[:id])
    if addon_item
      addon_item.destroy!
      render json: { code: 200 }
    else
      flash[:erorr] = "Addon item does not exists"
      render json: { code: 404 }
    end
  end

  def edit_addon_category
    session[:return_to] = request.referer
    @category = get_addon_category_through_id(decode_token(params[:category_id]))
    @branch = @category.branch
    render layout: "admin_application"
  end

  def update_addon_category
    @category = get_addon_category_through_id(params[:category_id])
    @branch = get_branch(params[:branch_id])

    if @category
      category_title = get_addon_category(params[:addon_category_name], @menu_item&.id)

      if category_title
        @category.update(min_selected_quantity: params[:min_selected_quantity], max_selected_quantity: params[:max_selected_quantity], addon_category_name_ar: params[:addon_category_name_ar], available: params[:available])
        flash[:success] = "successfully updated"
      else
        @category.update(addon_category_name: params[:addon_category_name], min_selected_quantity: params[:min_selected_quantity], max_selected_quantity: params[:max_selected_quantity], addon_category_name_ar: params[:addon_category_name_ar], available: params[:available])
        flash[:success] = "successfully updated"
      end
    else
      flash[:error] = "Addon category not exists"
    end

    redirect_to session.delete(:return_to)
  end

  def restaurant_menu_managment
    @restaurant = get_restaurant(decode_token(params[:restaurant_id]))

    if @restaurant
      @status = params[:status]
      @data = get_menu_data(params[:status], params[:page], params[:per_page], @restaurant).paginate(page: params[:page], per_page: 100)
      @menu_category = get_menu_data("menu_category", "", "", @restaurant).count
      @menu_item = get_menu_data("menu_item", "", "", @restaurant).count
      @addon_category = get_menu_data("addon_category", "", "", @restaurant).count
      @addon_item = get_menu_data("addon_item", "", "", @restaurant).count
    end

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.js { render "index", locals: { :@restaurant => @restaurant, :@status => @status, :@data => @data, :@menu_category => @menu_category, :@menu_item => @menu_item, :@addon_category => @addon_category, :@addon_item => @addon_item } }
    end
  end

  def restaurant_menu_approve
    data = get_menu_data_status(params[:item_type], params[:item_id])
    if data.present?
      if params[:status] == "approve"
        data.update(approve: true, is_rejected: false, resion: "")
        @admin = get_admin_user
        send_notification_to_business(params[:item_type], data, @admin, "Approved")
        # send_menu_approval_email(data)
        responce_json(code: 200, message: "Menu Approved!!")
        # else
        #   responce_json({code: 201, message: "Menu Rejected!!"})
      end
    else
      responce_json(code: 404, message: "Invalid!!")
    end
  end

  def restaurant_menu_reject
    data = get_menu_data_status(params[:item_type], params[:item_id])
    if data.present?
      data.update(is_rejected: true, resion: params[:reject_resion])
      @admin = get_admin_user
      send_notification_to_business(params[:item_type], data, @admin, "Rejected")
      # responce_json({code: 200, message: "Menu Approved!!"})
    end
    redirect_to restaurant_menu_managment_path(restaurant_id: params[:restaurant_id])
  end

  def menu_bulk_action
    @admin = get_admin_user
    @data_item = get_menu_data_status(params[:item_type], params[:item_ids].first)
    @branch = if params[:item_type] == "addon_category"
                @data_item.branch
              elsif params[:item_type] == "menu_item"
                @data_item.menu_category.branch
              elsif params[:item_type] == "addon_item"
                @data_item.item_addon_category.branch
              else
                @data_item.branch
              end

    if params[:action_type] == "approve"
      params[:item_ids].each do |item_id|
        @data = get_menu_data_status(params[:item_type], item_id)

        next unless @data
        @data.update(approve: true, is_rejected: false, resion: "")
        send_notification_to_business(params[:item_type], @data, @admin, "Bulk Approved")
      end

      flash[:success] = "Menu Approved!"
    else
      params[:item_ids].each do |item_id|
        @data = get_menu_data_status(params[:item_type], item_id)

        next unless @data
        @data.update(is_rejected: true, resion: params[:bulk_rejection_reason])
        send_notification_to_business(params[:item_type], @data, @admin, "Bulk Rejected")
      end

      flash[:success] = "Menu Rejected!"
    end

    bulk_notify_to_business(@branch.id, @branch.restaurant)
    redirect_to restaurant_menu_managment_path(restaurant_id: params[:restaurant_id], status: params[:item_type])
  end

  def request_resturant_csv
    @req_restaurant = get_request_restaurant(params[:restaurant])
    if @req_restaurant
      respond_to do |format|
        format.html
        format.csv do
          headers["Content-Disposition"] = "attachment; filename=\"Request Restaurant.csv\""
          headers["Content-Type"] ||= "text/csv"
        end
        format.xlsx { render xlsx: "request_resturant_csv", filename: "Request Restaurant.xlsx" }
      end
     end
  end

  def edit_request_restaurant
    @req_restaurant = get_request_restaurant(params[:id])
    render layout: "admin_application"
  end

  def update_request_restaurant
    @req_restaurant = get_request_restaurant(params[:req_restaurant_id])
    email = get_email_details(params[:email])
    if @req_restaurant.present? && (params[:email] == @req_restaurant.email)
      @req_restaurant.update(restaurant_name: params[:restaurant_name], owner_name: params[:owner_name], email: params[:email].downcase, contact_number: params[:full_phone], cpr_number: params[:cpr_number], restaurant_id: params[:restaurant_id], branch_no: params[:branch_no])
      flash[:success] = "successfully updated"
    elsif !email
      @req_restaurant.update(restaurant_name: params[:restaurant_name], owner_name: params[:owner_name], email: params[:email].downcase, contact_number: params[:full_phone], cpr_number: params[:cpr_number], restaurant_id: params[:restaurant_id], branch_no: params[:branch_no])
    else
      flash[:error] = "Email already exists. Please choose a different email!!"
    end
    redirect_to new_restaurant_path
  end

  def busy_restaurants
    @busy = get_all_busy_restaurant
    @countries = Country.where(id: @busy.pluck("restaurants.country_id").uniq).pluck(:name, :id).sort
    @busy = @busy.search_by_keyword(params[:searched_country_id], params[:searched_criteria], params[:keyword]).order_by_restaurant_title

    respond_to do |format|
      format.html {
        @busy = @busy.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      }

      format.csv  { send_data @busy.busy_list_csv, filename: "busy_restaurants_list.csv" }
    end
  end

  def close_restaurants
    @close = get_all_close_restaurant
    @countries = Country.where(id: @close.pluck("restaurants.country_id").uniq).pluck(:name, :id).sort
    @close = @close.search_by_keyword(params[:searched_country_id], params[:searched_criteria], params[:keyword]).order_by_restaurant_title

    respond_to do |format|
      format.html {
        @close = @close.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "admin_application"
      }

      format.csv  { send_data @close.closed_list_csv, filename: "closed_restaurants_list.csv" }
    end
  end

  def add_restaurant_owner
    @restaurant = get_restaurant_data(decode_token(params[:id]))
    render layout: "admin_application"
  end

  def add_new_owner
    @restaurant = get_restaurant_data(params[:restaurant_id])
    user = user_deatils_with_role(params[:email], "business")
    email = get_email_details(params[:email])
    if @restaurant && !email
      if !user
        password = SecureRandom.hex(5)
        user = User.create_restaurant_owner_by_admin(params[:owner_name], params[:email], params[:full_phone])
        if user[:code] == 200
          auth = Auth.create_user_password(user[:result], password, "business")
          @restaurant.update(user_id: user[:result].id)
          send_email_on_restaurant_owner(user[:result].email, user[:result].name, password)
        end
        flash[:success] = "Successfully Added"
      else
        @restaurant.update(user_id: user.id)
        flash[:success] = "Successfully updated."
        end
    else
      flash[:error] = "Please add valid email!!"
      end
    redirect_to restaurant_list_path
  end

  def edit_user
    @restaurant = get_restaurant_data(decode_token(params[:id]))
    render layout: "admin_application"
  end

  def update_user
    @restaurant = get_restaurant_data(params[:id])
    @restaurant_owner = @restaurant.user
    user = user_deatils_with_role(params[:email], "business")
    if @restaurant.present? && @restaurant_owner.email == params[:email]
      @restaurant.update(title: params[:restaurant_name])
      @restaurant_owner.update(name: params[:owner_name], contact: params[:full_phone], email: @restaurant_owner.email.downcase)
      flash[:success] = "Restaurant details successfully update."
    elsif @restaurant_owner.email != params[:email]
      if !user
        user = User.create_restaurant_owner_by_admin(params[:owner_name], params[:email], params[:full_phone])
        if user[:code] == 200
          password = SecureRandom.hex(5)
          auth = Auth.create_user_password(user[:result], password, "business")
          @restaurant.update(user_id: user[:result].id)
          send_email_on_restaurant_owner(user[:result].email, user[:result].name, password)
        else
          @restaurant.update(user_id: user.id)
          flash[:success] = "Restaurant details successfully update."
        end
        flash[:success] = "Successfully Added"
      else
        @restaurant.update(user_id: user.id)
        flash[:success] = "Successfully updated."
      end
    end
    redirect_to restaurant_list_path
  end

  def add_new_user; end

  def admin_edit_restaurant_details
    @restaurant = get_restaurant_deatils(decode_token(params[:restaurant_id]))
    render layout: "admin_application"
  end

  def admin_update_restaurant_details
    @restaurant = get_restaurant_deatils(decode_token(params[:restaurant_id]))
    if @restaurant
      update_restaurant(@restaurant, params[:restaurant_logo].present? ? params[:restaurant_logo] : "", params[:restaurant_name], params[:restaurant_name_ar], params[:owner_name])
      flash[:success] = "Update Successfully"
      redirect_to restaurant_list_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = "Invalid details"
      redirect_to restaurant_list_path(restaurant_id: params[:restaurant_id])
    end
  end

  def admin_upload_contract_doc
    restaurant = get_restaurant_data(params[:restaurant_id])
    @user = restaurant.user
    if restaurant
      @admin = SuperAdmin.first
      document = restaurant.restaurant_document
      if document
        delete_perfile = delete_perivious_file_on_dropbox(document)
        url = upload_doc_on_dropbox
        update_doc = document.update(doc_url: url) if url.present?
        redirect_to restaurant_list_path
      else
        url = upload_doc_on_dropbox
        RestaurantDocument.create(restaurant_id: restaurant.id, doc_url: url)
        redirect_to restaurant_list_path
      end
    else
      redirect_to restaurant_list_path
    end

    rescue Exception => e
  end

  def edit_restaurant_branch
    # @restaurant = get_restaurant_data(params[:id])
    @branch = get_branch_data(params[:id])
    @brand = @branch.restaurant
    @restaurant = @branch.restaurant.user
    country_id = Country.find_by(name: @branch.country)
    @areas = get_coverage_area_web("", 1, 300).where(country_id: country_id)
    @branchCoverage = @branch.branch_coverage_areas.first
    @branchArea = @branchCoverage.present? ? @branchCoverage.coverage_area : []
    @branch_slots = BranchSubscription.where(country_id: @branch.restaurant.country_id).pluck(:fee, :id)
    @report_slots = ReportSubscription.where(country_id: @branch.restaurant.country_id).pluck(:fee, :id)
    render layout: "admin_application"
  end

  def update_restaurant_branch
    @branch = get_branch_data(params[:branch_id])
    if @branch
      branch = update_branch(params[:address].strip, params[:full_phone].strip, @branch.delivery_time, @branch.min_order_amount, @branch.cash_on_delivery, @branch.accept_cash, @branch.accept_card, params[:country].strip, params[:area].strip, params[:tax_percentage], @branch.delivery_charges, params[:branch_image], params[:latitude], params[:longitude], "", "", params[:branch_fee_id], params[:report_fee_id], params[:full_phone_call_center].to_s.squish, params[:report], params[:fixed_charge_percentage], params[:max_fixed_charge])
      redirect_to branch_show_path(encode_token(@branch.restaurant.id))
    else
      flash[:erorr] = "Restaurant does not exits!!"
      redirect_to branch_show_path
    end
  end

  def download_area_upload_format_doc
    @branch = get_branch_data(decode_token(params[:id]))

    if @branch
      @areas = get_branch_coverage_area_list(@branch)

      respond_to do |format|
        format.html
        format.csv do
          headers["Content-Disposition"] = "attachment; filename=\"Coverage-Area-Upload-Format.csv\""
          headers["Content-Type"] ||= "text/csv"
        end
        format.xlsx { render xlsx: "download_area_upload_format_doc", filename: "Coverage-Area-Upload-Format.xlsx" }
      end
     end
  end

  def upload_area_format_doc
    # begin
    @branch = get_branch_data(decode_token(params[:branch_id]))
    if @branch
      file = params[:upload_covrage_area_document][:file]
      @i = 1
      @count = []
      @status = false
      extname = File.extname(file.original_filename)

      if extname == ".xlsx"
        xlsx = Roo::Excelx.new(file.path)
        xlsx.each do |row|
          if @i == 1
            if (row[0] == "ID") && (row[1] == "Area Name") && (row[2] == "Delivery Charges") && (row[3] == "Minimum Amount") && (row[4] == "Delivery Time") && (row[5] == "Third Party Delivery") && (row[6] == "Third Party Delivery Type") && (row[7] == "Cash On Delivery") && (row[8] == "Accept Cash") && (row[9] == "Accept Card") && (row[10] == "Closed") && (row[11] == "Busy") && (row[12] == "Far menu")
              @status = true
            else
              @status = false
              break
             end
          else
            area = @branch.branch_coverage_areas.find_by(coverage_area_id: row[0])

            if area.present?
              area.update(delivery_charges: row[2], minimum_amount: row[3], delivery_time: row[4], third_party_delivery: row[5], third_party_delivery_type: row[6], branch_id: @branch.id, coverage_area_id: row[0], cash_on_delivery: row[7], accept_cash: row[8], accept_card: row[9], is_closed: row[10], is_busy: row[11], far_menu: row[12])
            else
              BranchCoverageArea.create(delivery_charges: row[2], minimum_amount: row[3], delivery_time: row[4], third_party_delivery: row[5], third_party_delivery_type: row[6], branch_id: @branch.id, coverage_area_id: row[0], cash_on_delivery: row[7], accept_cash: row[8], accept_card: row[9], is_closed: row[10], is_busy: row[11], far_menu: row[12])
            end
           end

          @i += 1
        end
      end

      @status ? flash[:success] = "Coverage Area activated successfully" : flash[:error] = "Please provide valid document"
      redirect_back(fallback_location: root_path)
    else
      flash[:error] = "Invalid branch"
      redirect_back(fallback_location: root_path)
    end
  end

  def remove_restaurant_branch
    branch = get_restaurant_branch(params[:id])
    if branch
      branch.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Branch does not exists"
      render json: { code: 404 }
    end
    rescue Exception => e
  end

  def restaurant_rating_remove
    review = restaurant_rating_by_id(params[:id])
    if review
      review.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Review does not exists"
      render json: { code: 404 }
    end

    rescue Exception => e
  end

  def restaurant_order_rating_remove
    order_rating = get_restaurant_order_rating(params[:id])
    if order_rating
      order_rating.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Review does not exists"
      render json: { code: 404 }
    end
    rescue Exception => e
  end

  def remove_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
    @restaurant.destroy
    flash[:success] = "Restaurant Successfully Deleted!"
    redirect_to request.referer
  end

  private

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
  rescue ActiveRecord::StatementInvalid => e
  end
end
