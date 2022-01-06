class Business::BranchesController < ApplicationController
  before_action :authenticate_business, except: [:upload_contract_doc, :remove_menu_addon_category, :remove_menu_addon_item]
  before_action :find_area
  def index
    @branches = @user.restaurant.branches.paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
    rescue Exception => e
  end

  def view_branch
    @branch = @user.restaurant.branches.find_by(id: params[:id])
    @branches = @user.restaurant.branches
    @orders = get_partners_order_list(@branch, params[:keyword])
    @transporters = find_branch_transporter(@branch)
    @managers = find_branch_managers(@branch)
    render layout: "partner_application"
    rescue Exception => e
  end

  def download_template
    send_file("#{Rails.root}/template.csv") 
  end

  def bulk_customer_creation
    csv_file = CSV.read(params[:attachments].tempfile)
    csv_file.each_with_index do |data, index|
      if index != 0
        area = CoverageArea.find_by("lower(area) = ?", data[3].downcase)
        restaurant = Restaurant.find_by("lower(title) = ?", data[13].downcase)
        if area.present? && restaurant.present?
          email = data[0]
          name = data[1]
          country_code = data[11]
          @customer = User.find_by(email: email) || User.create(name: name, email: email, contact: "+#{data[11]}#{data[12]}")
          @customer.update(restaurant_user_id: restaurant.id)
          if @customer.auths.blank?
            Auth.create_user_password(@customer, data[2], "customer")
          end
          @address = Address.create(address_type: data[5], address_name: data[4], block: data[6], street: data[7], building: data[8], floor: data[9], apartment_number: data[10], country_code: data[11], contact: data[12], user_id: @customer.id, coverage_area_id: area.id, area: area.area)
        end
      end
    end
    render :js => "window.location = '#{business_customers_list_path(restaurant_id: params[:restaurant_id])}'"
  end

  def customers_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @countries = Country.where(id: User.joins(:auths).where(auths: { role: "customer" }).pluck(:country_id).uniq).pluck(:name, :id).sort
    @states = State.where(id: User.joins(:delivery_company).pluck("delivery_companies.state_id").uniq).pluck(:name, :id).sort
    @companies = DeliveryCompany.joins(users: :auths).where(auths: { role: "transporter" }).distinct.pluck(:name, :id).sort
    @restaurants = Restaurant.joins(:branches).where(branches: { id: User.joins(:branches).pluck("branches.id") }).distinct.pluck(:title, :id).sort
    @users = search_user_list("customer", params[:keyword], restaurant, params[:searched_country_id], params[:searched_state_id], params[:searched_company_id], params[:searched_restaurant_id], params[:start_date], params[:end_date])
    restu_user = resturant_search_user_list("customer", params[:keyword], restaurant, params[:start_date], params[:end_date])
    @users = restu_user + @users
    respond_to do |format|
      format.html do
        @users = @users.paginate(page: params[:page], per_page: params[:per_page])
        render layout: "partner_application"
      end
      format.csv { send_data @users.user_list_csv("customer"), filename: "user_list.csv" }
    end
  end

  def new_customer_master_key
    @note = params[:note]
    area = CoverageArea.find(params[:area_id])
    email = params[:user_email]
    name = params[:user_name]
    country_code = params[:address_contact_number].to_s.gsub(params[:mobile].to_s, "")
    @customer = User.find_by(email: email) || User.create(name: name, email: email, contact: params[:mobile])
    @customer.update(restaurant_user_id: decode_token(params[:restaurant_id]))
    if @customer.auths.blank?
      Auth.create_user_password(@customer, "123456", "customer")
    end

    if params[:address_id].present?
      @address = Address.find(params[:address_id])
      @address.update(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], coverage_area_id: area.id, area: area.area)
    else
      @address = Address.create(address_type: params[:address_type], address_name: params[:address_name], block: params[:block], street: params[:road], building: params[:building], floor: params[:floor], apartment_number: params[:apartment_number], additional_direction: params[:additional_direction], country_code: country_code, contact: params[:mobile], landline: params[:landline], user_id: @customer.id, coverage_area_id: area.id, area: area.area)
    end
    redirect_to business_customers_list_path(restaurant_id: params[:restaurant_id])
  end

  def restaurant
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @restaurant = restaurant
      @report_subs_fee = Servicefee.all
      branches = @restaurant.branches.pluck(:id)
      # area = BranchCoverageArea.where(:branch_id=>branches)
      @closed_branches = @restaurant.branches.where(is_closed: true).count # area.where(:is_closed=>true).count
      @open_branches = @restaurant.branches.where(is_closed: false, is_busy: false).count
      @busy_branches = @restaurant.branches.where(is_busy: true).count
      @taotal_sales  = get_restaurant_sales(branches)

      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end

    rescue Exception => e
  end

  def resturant_branch
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = if restaurant
                  restaurant.branches.includes(:branch_coverage_areas, :coverage_areas)
                else
                  @user.manager_branches.includes(:branch_coverage_areas, :coverage_areas)
                end
    render layout: "partner_application"
    rescue Exception => e
  end

  def manager_restaurant_branch
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = if restaurant
                  @user.restaurant.branches
                else
                  @user.manager_branches
                end
    render layout: "partner_application"
    rescue Exception => e
  end

  def upload_csv
    @branch = get_branch_data(params[:branch_id])
    import_data = @branch.import(params[:file])

    if import_data.present?
      flash[:success] = "Menu Imported Successfully!"
    else
      flash[:error] = "Upload xls file format only!"
    end

    redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: encode_token(@branch.restaurant_id))
  end

  def branch_menu
    # begin
    @branch = get_branch_data(decode_token(params[:id]))
    if @branch
      @menu_categories = branch_menu_category(@branch, params[:keyword], params[:category])
      @menu_items = branch_menu_item(@branch, @menu_categories, params[:keyword], params[:category])
      @addon_categories = branch_addon_category(@branch, params[:keyword], params[:category])
      # @addon_items = branch_addon_item(@branch,@addon_categories,params[:keyword],params[:category])
      @daily_dishes = @branch.menu_categories.find_by(category_title: "Daily Dishes")
      @catering = @branch.menu_categories.find_by(category_title: "Catering")
      @item_cat_addons = branch_addon_category(@branch, params[:keyword], params[:category])
    else
      flash[:erorr] = "Branch does not exits!!"
      redirect_back(fallback_location: business_restaurant_branches_path)
    end
    render layout: "partner_application"
    # rescue Exception => e
    #   redirect_to_root()
    # end

    rescue Exception => e
  end

  def add_menu_item
    @branch = get_branch(decode_token(params[:branch_id]))
    @menu_category = find_menu_category_by_branch(@branch.id)
    @item_cat_addons = @branch.item_addon_categories
    render layout: "partner_application"
  end

  def add_new_menu_item
    # begin
    @branch = get_branch(params[:branch_id])
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    item = get_menu_item_name_catId(params[:item_name].strip, params[:menu_category_id].strip)
    if restaurant
      if !item
        status = is_new_menu_item(params[:item_name].strip, params[:price_per_item].strip, params[:image], params[:cropped_image], params[:item_description].strip, params[:menu_category_id].strip, params[:is_available].strip, params[:item_name_ar].strip, params[:item_description_ar].strip, params[:calorie].strip, false, params[:addon_category_id], params[:dish_date], params[:far_menu], params[:include_in_pos], params[:include_in_app], params[:preparation_time] , params[:recipe_ids], params[:station_ids])
        @admin = get_admin_user
        restaurant_title = restaurant.title
        type = "add_menu_item"
        msg = "#{restaurant_title} restaurant has added new menu item"
        send_email_to_foodclube(@user, "Add New Menu Item", msg)
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        flash[:success] = "Menu Item added sucessfully"
      else
        flash[:error] = "Already exists"
      end
    else
      if !item
        status = is_new_menu_item(params[:item_name].strip, params[:price_per_item].strip, params[:image], params[:cropped_image], params[:item_description].strip, params[:menu_category_id].strip, params[:is_available].strip, params[:item_name_ar].strip, params[:item_description_ar].strip, params[:calorie].strip, false, params[:addon_category_id], params[:dish_date], params[:far_menu], params[:include_in_pos], params[:include_in_app], params[:preparation_time], params[:recipe_ids], params[:station_ids])
        @admin = get_admin_user
        restaurant_title =  @branch.restaurant.title
        type = "add_menu_item"
        msg = "#{restaurant_title} restaurant has added new menu item"
        send_email_to_foodclube(@user, "Add New Menu Item", msg)
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        flash[:success] = "Menu Item added sucessfully"
      else
        flash[:error] = "Already exists"
      end
    end
    redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: params[:restaurant_id])
    # rescue Exception => e
    #   redirect_to_root()
    # end
  end

  def add_branch_coverage_area
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300)
    if restaurant
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    else
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    end

    rescue Exception => e
  end

  def branch_new_coverage_area
    @area = CoverageArea.find_by(id: params[:area])
    if @area
      area = add_area(params[:delivery_charges].strip, params[:minimum_order_amount].strip, params[:max_delivery_time].strip, params[:opening_time], params[:closing_time], params[:branch].strip, params[:area], params[:cash_on_delivery], params[:accept_cash], params[:accept_card])
      flash[:success] = "Coverage area update successfully."
    else
      flash[:error] = "Coverage area Invalid."
    end
    redirect_to business_branch_coverage_area_path(branch_id: encode_token(params[:branch]), restaurant_id: params[:restaurant_id])
    rescue Exception => e
  end

  def branch_coverage_area
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branch = get_branch(decode_token(params[:branch_id]))
    @areas = @branch.branch_coverage_areas
    @areas = @areas.joins(:coverage_area).where("coverage_areas.area LIKE ?", "%#{params[:keyword]}%").uniq if params[:keyword].present?
    @other_coverage_areas = CoverageArea.active_areas.where(country_id: @branch.restaurant.country_id).where.not(id: @areas.pluck(:coverage_area_id).uniq)
    @other_coverage_areas = @other_coverage_areas.where("area LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @all_areas = (@areas.to_a + @other_coverage_areas.to_a).paginate(page: params[:page], per_page: (params[:per_page] || 20))
    render layout: "partner_application"
    rescue Exception => e
  end

  def update_coverage_area
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @area = get_branch_caverage_area(decode_token(params[:coverage_area_id]))
      @branchCoverage = @area.coverage_area
      @areas = CoverageArea.where(country_id: restaurant.country_id).order(:area)
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    else
      @area = get_branch_caverage_area(decode_token(params[:coverage_area_id]))
      @branchCoverage = @area.coverage_area
      @areas = CoverageArea.all
      @branches = @user.auths.first.role == "business" ? restaurant.branches : @user.manager_branches
      render layout: "partner_application"
    end

    rescue Exception => e
  end

  def edit_coverage_area
    # daily_open_at: params[:opening_time], daily_closed_at:params[:closing_time]
    @area = get_branch_caverage_area(params[:coverage_id])
    checkArea = branch_caverage_area(params[:area], params[:branch])
    if @area && checkArea.blank?
      area = @area.update(delivery_charges: params[:delivery_charges].strip, minimum_amount: params[:minimum_order_amount].strip, delivery_time: params[:max_delivery_time].strip, branch_id: params[:branch].strip, coverage_area_id: params[:area], cash_on_delivery: params[:cash_on_delivery], accept_cash: params[:accept_cash], accept_card: params[:accept_card], third_party_delivery: params[:third_party_delivery], third_party_delivery_type: params[:third_party_delivery] == "true" ? params[:third_party_delivery_type] : nil, is_active: true)
      flash[:success] = "Coverage area update successfully."
    else
      area = @area.update(delivery_charges: params[:delivery_charges].strip, minimum_amount: params[:minimum_order_amount].strip, delivery_time: params[:max_delivery_time].strip, branch_id: params[:branch].strip, cash_on_delivery: params[:cash_on_delivery], accept_cash: params[:accept_cash], accept_card: params[:accept_card], third_party_delivery: params[:third_party_delivery], third_party_delivery_type: params[:third_party_delivery] == "true" ? params[:third_party_delivery_type] : nil, is_active: true)
      flash[:success] = "Coverage area update successfully."
    end
    redirect_to business_branch_coverage_area_path(encode_token(@area.branch.id), restaurant_id: params[:restaurant_id])
    rescue Exception => e
  end

  def add_new_branch_timing
    @count = params[:count].to_i + 1
    @day = params[:day]
  end

  def add_branch
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @restaurant = restaurant
      @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
      render layout: "partner_application"
    else
      @restaurant = @user.manager_branches.first.restaurant
      @areas = CoverageArea.where(country_id: @restaurant.country_id)
      render layout: "partner_application"
    end
    rescue Exception => e
  end

  def add_new_branch
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      branch = branch_add(restaurant, params[:address].strip, params[:full_phone].strip, "", "", "", "", "", params[:country].strip, params[:area].strip, params[:tax_percentage], "", params[:branch_image], params[:latitude], params[:longitude], params[:cr_document], params[:cpr_document])
      @admin = SuperAdmin.first

      if branch[:code] == 200
        branch_id = branch[:result].id

        params.select { |k, _v| k.include?("opening_time") }.each do |k, v|
          day = k.split("_")[2]
          count = k.split("_")[3]

          if params["open_#{day}"] == "1"
            BranchTiming.create(opening_time: params["opening_time_#{day}_#{count}"], closing_time: params["closing_time_#{day}_#{count}"], day: day, branch_id: branch_id)
          end
        end
      end

      begin
        RestaurantMailer.send_email_to_admin_new_branch(restaurant, @admin).deliver_now
        @webPusher = web_pusher(Rails.env)
        pusher_client = Pusher::Client.new(
          app_id: @webPusher[:app_id],
          key: @webPusher[:key],
          secret: @webPusher[:secret],
          cluster: "ap2",
          encrypted: true
        )
        pusher_client.trigger("my-channel", "my-event", {
                                # message: 'hello world'
                              })
        Notification.create!(message: "#{restaurant.title} restaurant has added new branch", notification_type: "restaurant_branch", user_id: @user.id, admin_id: @admin.id, restaurant_id: restaurant.id)
      rescue Exception => e
      end

      redirect_to business_resturant_branch_path(restaurant_id: params[:restaurant_id])
    else
      flash[:erorr] = "Restaurant does not exits!!"
      redirect_to business_resturant_branch_path
    end
  end

  def edit_branch
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branch = get_branch_data(decode_token(params[:id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @branch.restaurant.country_id)
    @branchCoverage = @branch.branch_coverage_areas.first
    @branchArea = @branchCoverage.present? ? @branchCoverage.coverage_area : []
    render layout: "partner_application"
    rescue Exception => e
  end

  def update_branch_info
    @branch = get_branch_data(params[:branch_id])

    if @branch
      branch = update_branch(params[:address].strip, params[:full_phone].strip, "", "", "", "", "", params[:country].strip, params[:area].strip, params[:tax_percentage], "", params[:branch_image], params[:latitude], params[:longitude], params[:cr_document], params[:cpr_document], nil, nil, @branch.call_center_number, @branch.report, @branch.fixed_charge_percentage, @branch.max_fixed_charge)

      if @user.auths.first.role == "business"
        redirect_to business_resturant_branch_path(restaurant_id: encode_token(@branch.restaurant_id))
      elsif @user.auths.first.role == "manager"
        redirect_to business_manager_restaurant_branch_path
      else
        redirect_to business_restaurant_branches_path
      end
    else
      flash[:erorr] = "Restaurant does not exits!!"
      redirect_to business_restaurant_branches_path
    end

    rescue Exception => e
  end

  def subscribe_report
    restaurant = get_restaurant_data(params[:restaurant_id])
    if restaurant
      report = get_subscribe_report(restaurant, params[:status])
      responce_json(code: report[:code], message: report[:message])
    else
      responce_json(code: 422, message: "Invalid Request")
    end
    rescue Exception => e
  end

  def upload_contract_doc
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @user = restaurant.user
    if restaurant
      @admin = SuperAdmin.first
      document = restaurant.restaurant_document
      if document
        delete_perfile = delete_perivious_file_on_dropbox(document)
        url = upload_doc_on_dropbox
        update_doc = document.update(doc_url: url) if url.present?
        begin
          @webPusher = web_pusher(Rails.env)
          pusher_client = Pusher::Client.new(
            app_id: @webPusher[:app_id],
            key: @webPusher[:key],
            secret: @webPusher[:secret],
            cluster: "ap2",
            encrypted: true
          )
          pusher_client.trigger("my-channel", "my-event", {
                                  # message: 'hello world'
                                })
          Notification.create!(message: "#{restaurant.title} has uploaded contract document", notification_type: "restaurant_contract", user_id: @user.id, admin_id: @admin.id)
        end
        flash[:success] = "Restaurant uploaded contract document successfully!!"
        redirect_to business_restaurant_path(restaurant_id: params[:restaurant_id])
        # render :layout => "partner_application"
      else
        url = upload_doc_on_dropbox
        RestaurantDocument.create(restaurant_id: restaurant.id, doc_url: url)
        begin
          @webPusher = web_pusher(Rails.env)
          pusher_client = Pusher::Client.new(
            app_id: @webPusher[:app_id],
            key: @webPusher[:key],
            secret: @webPusher[:secret],
            cluster: "ap2",
            encrypted: true
          )
          pusher_client.trigger("my-channel", "my-event", {
                                  # message: 'hello world'
                                })
          Notification.create(message: "#{restaurant.title} has uploaded contract document", notification_type: "restaurant_contract", user_id: @user.id, admin_id: @admin.id)
        end
        flash[:success] = "Restaurant uploaded contract document successfully!!"
        redirect_to business_restaurant_path(restaurant_id: params[:restaurant_id])
      end

    else
      redirect_to business_restaurant_path(restaurant_id: params[:restaurant_id])
    end

    rescue Exception => e
  end

  def add_menu_category
    @branch = get_branch(decode_token(params[:branch_id]))
    render layout: "partner_application"
    rescue Exception => e
  end

  def menu_category_add
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @branch = get_branch(params[:branch_id])
      @admin =  get_admin_user
      menu_category = find_menu_category_branch(params[:category_title].strip, params[:branch_id].strip)
      if !menu_category
        menu_category = new_menu_category(params[:category_title].strip, params[:category_title_ar].strip, params[:branch_id].strip, false, params[:available])
        menu_category.update(
          station_ids: params[:station_ids],
          start_date: params[:start_date]&.strip,
          end_date: params[:end_date]&.strip,
          start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"),
          end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"),
          include_in_pos: params[:include_in_pos], include_in_app: params[:include_in_app]
        )
        title = restaurant.title
        msg = "#{title} restaurant has add new menu category"
        type = "add_menu_category"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id) if menu_category.present?
        flash[:success] = "Menu category added successfully"
      else
        flash[:error] = "Menu category already exists"
      end
      redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: params[:restaurant_id])
    else
      @branch = get_branch(params[:branch_id])
      @admin = get_admin_user
      menu_category = find_menu_category_branch(params[:category_title].strip, params[:branch_id].strip)
      if !menu_category
        menu_category = new_menu_category(params[:category_title].strip, params[:category_title_ar].strip, params[:branch_id].strip, false, params[:available])
        menu_category.update(start_date: params[:start_date]&.strip, end_date: params[:end_date]&.strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"))
        title = @user.manager_branches.first.restaurant.title
        msg = "#{title} restaurant has add new menu category"
        type = "add_menu_category"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id) if menu_category.present?
        flash[:success] = "Menu category added successfully"
      else
        flash[:error] = "Menu category already exists"
      end
      redirect_to business_branch_menu_items_path(encode_token(@branch.id))
    end

    rescue Exception => e
  end

  def update_branch_menu_category
    @menu_category = get_menu_category(decode_token(params[:category_id]))
    render layout: "partner_application"
    rescue Exception => e
  end

  def edit_branch_menu_category
    # begin
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      menu_category = get_menu_category(params[:category_id])
      category = find_menu_category_branch(params[:category_title].strip, params[:branch_id])
      @admin = get_admin_user
      if menu_category
        menu_category.update(
          station_ids: params[:station_ids],
          start_date: params[:start_date]&.strip,
          end_date: params[:end_date]&.strip,
          start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"),
          end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"),
          include_in_pos: params[:include_in_pos], include_in_app: params[:include_in_app]
          )
        is_update_menu_category(menu_category, params[:category_title].strip, params[:category_title_ar].strip, menu_category.branch.id, params[:category_priority], params[:available])
        restaurant = @user.auths.first.role == "business" ? restaurant : @user.manager_branches.first.restaurant
        title = restaurant.title
        msg = "#{title} restaurant has update menu category"
        type = "menu_category_update"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
        menu_category.fill_changed_fields(menu_category.saved_changes.keys)
        flash[:success] = "Menu Category updated successfully"
      else
        flash[:error] = "Menu category already exists"
      end
      redirect_to business_branch_menu_items_path(encode_token(menu_category.branch.id), restaurant_id: params[:restaurant_id])
    else
      menu_category = get_menu_category(params[:category_id])
      category = find_menu_category_branch(params[:category_title].strip, params[:branch_id])
      @admin = get_admin_user
      if menu_category
        menu_category.update(start_date: params[:start_date]&.strip, end_date: params[:end_date]&.strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time])&.strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time])&.strftime("%H:%M"))
        is_update_menu_category(menu_category, params[:category_title].strip, params[:category_title_ar].strip, menu_category.branch.id, params[:category_priority], params[:available])
        restaurant = @user.manager_branches.first.restaurant
        title = restaurant.title
        msg = "#{title} restaurant has update menu category"
        type = "menu_category_update"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
        menu_category.fill_changed_fields(menu_category.saved_changes.keys)
        flash[:success] = "Menu Category updated successfully"
      else
        flash[:error] = "Menu category already exists"
      end
      redirect_to business_branch_menu_items_path(encode_token(menu_category.branch.id), restaurant_id: params[:restaurant_id])
    end
    # rescue Exception => e
    #   redirect_to_root()
    # end
  end

  def branch_menu_category_item_list
    @category = MenuCategory.find(decode_token(params[:menu_category_id]))
    @items = @category.menu_items
    @items = @items.search_by_name(params[:keyword]) if params[:keyword].present?
    @items = @items.paginate(page: params[:page], per_page: 50)
    @restaurant_id = @category.branch.restaurant_id
    render layout: "partner_application"
  end

  def edit_branch_menu_item
    session[:return_to] = request.referer
    @branch = get_branch(decode_token(params[:branch_id]))
    @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    @addon_category = @menu_item.item_addon_categories.pluck(:id)
    @date = @menu_item.menu_item_dates.where("DATE(menu_date) >= (?)", Date.today).order("menu_date ASC").pluck(:menu_date)
    @allDate = @date.map { |d| d.strftime("%Y-%m-%d") }.join(", ")
    @item_cat_addons = @branch.item_addon_categories
    @menu_category = find_menu_category_by_branch(decode_token(params[:branch_id]))
    menu_items = branch_menu_item(@branch, @menu_category, params[:keyword], params[:category])
    @selected_menu_items = menu_items.where.not(id: @menu_item.id)
    render layout: "partner_application"
  end

  def update_branch_menu_item
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @branch = get_branch(params[:branch_id])
      item = get_menu_id_catId(params[:menu_item_id], params[:menu_category_id])
      if item
        item_status = params[:is_available] != "true"
        status = is_update_menu_item(item, params[:item_name].strip, params[:price_per_item].strip, params[:image], params[:cropped_image], params[:item_description].strip, params[:menu_category_id].strip, params[:is_available].strip, params[:item_name_ar].strip, params[:item_description_ar].strip, item_status, params[:calorie].strip, params[:dish_date], params[:addon_category_id], params[:far_menu], params[:include_in_pos], params[:include_in_app], params[:menu_item][:menu_item_ids], params[:recipe_ids], params[:station_ids])
        @admin = get_admin_user
        title = restaurant.title
        msg = "#{title} restaurant has update menu item"
        type = "menu_item_update"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        item.update(preparation_time: params["preparation_time"]) if(params["preparation_time"].present?)
        if item.saved_changes.keys.reject { |k| ["approve", "updated_at"].include?(k) }.empty?
          item.update(approve: true)
        else
          item.fill_changed_fields(item.saved_changes.keys)
        end

        # if (status.present? and item_status == false)
        flash[:success] = "Menu Item updated successfully"
      else
        flash[:error] = "Item not exists"
      end
    else
      @branch = get_branch(params[:branch_id])
      item = get_menu_id_catId(params[:menu_item_id], params[:menu_category_id])

      if item
        item_status = params[:is_available] != "true"
        status = is_update_menu_item(item, params[:item_name].strip, params[:price_per_item].strip, params[:image], params[:cropped_image], params[:item_description].strip, params[:menu_category_id].strip, params[:is_available].strip, params[:item_name_ar].strip, params[:item_description_ar].strip, item_status, params[:calorie].strip, params[:dish_date], params[:addon_category_id], params[:far_menu], params[:include_in_pos], params[:include_in_app],params[:menu_item][:menu_item_ids], params[:recipe_ids], params[:station_ids])
        @admin = get_admin_user
        title = @user.manager_branches.first.restaurant.title
        msg = "#{title} restaurant has update menu item"
        type = "menu_item_update"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        item.fill_changed_fields(item.saved_changes.keys)
        flash[:success] = "Menu Item updated successfully"
      else
        flash[:error] = "Item not exists"
      end
    end
    redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: params[:restaurant_id])
  end

  def menu_item_addon_list
    @branch = get_branch(decode_token(params[:branch_id]))
    @cat_addons = ItemAddonCategory.all
    @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    @item_cat_addons = @branch.item_addon_categories
    render layout: "partner_application"
  end

  def add_manu_addon_category
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branch = get_branch(decode_token(params[:branch_id]))
    render layout: "partner_application"
    rescue Exception => e
  end

  def new_menu_addon_category
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branch = get_branch_data(decode_token(params[:branch_id]))
    if restaurant || @branch
      category = get_branch_addon_category(params[:addon_category_name].strip, @branch.id)
      if !category
        addon_category = addon_category_add(@branch, params[:addon_category_name].strip, params[:addon_category_name_ar].strip, params[:min_selected_quantity].strip.presence || 0, params[:max_selected_quantity].strip.presence || 0, false, params[:available])
        @admin =  get_admin_user
        restaurant = restaurant.presence || @branch.restaurant
        title = restaurant.title
        msg = "#{title} restaurant has add addon item category"
        type = "add_addon_category"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id) if addon_category.present?
      else
        flash[:error] = "Addon category already exists"
      end
    else
      flash[:error] = "Addon category already exists"
    end
    redirect_to business_branch_menu_items_path(id: params[:branch_id], restaurant_id: params[:restaurant_id])
  end

  def edit_menu_addon_category
    # @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    @category = get_addon_category_through_id(decode_token(params[:category_id]))
    @branch = @category.branch
    render layout: "partner_application"
  end

  def update_menu_addon_category
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @category = get_addon_category_through_id(params[:category_id])
    @branch = get_branch_data(decode_token(params[:branch_id]))
    if restaurant
      if @category
        @category.update(addon_category_name: params[:addon_category_name].strip, min_selected_quantity: params[:min_selected_quantity].strip, max_selected_quantity: params[:max_selected_quantity].strip, addon_category_name_ar: params[:addon_category_name_ar].strip, approve: false, is_rejected: false, available: params[:available])
        @admin = get_admin_user
        title = restaurant.title
        msg = "#{title} restaurant has update addon item category"
        type = "update_addon_category"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        @category.fill_changed_fields(@category.saved_changes.keys)
      else
        flash[:error] = "Addon category not exists"
      end
      redirect_to business_branch_menu_items_path(id: params[:branch_id], restaurant_id: params[:restaurant_id])
    else
      if @category
        @category.update(addon_category_name: params[:addon_category_name].strip, min_selected_quantity: params[:min_selected_quantity].strip, max_selected_quantity: params[:max_selected_quantity].strip, addon_category_name_ar: params[:addon_category_name_ar].strip, approve: false, is_rejected: false, available: params[:available])
        @admin = get_admin_user
        title = @user.manager_branches.first.restaurant.title
        msg = "#{title} restaurant has update addon item category"
        type = "update_addon_category"
        send_notification_releted_menu(msg, type, @user, @admin, @branch.restaurant.id)
        @category.fill_changed_fields(@category.saved_changes.keys)
        # end
      else
        flash[:error] = "Addon category not exists"
      end
      redirect_to business_branch_menu_items_path(id: params[:branch_id])
    end

    rescue Exception => e
  end

  def menu_addon_item
    # @menu_item = get_menu_item(decode_token(params[:menu_item_id]))
    # @addon_categories = @menu_item.item_addon_categories
    # @branch = @menu_item.menu_category.branch
    @branch = get_branch_data(decode_token(params[:branch_id]))
    @addon_categories = @branch.item_addon_categories
    render layout: "partner_application"
    rescue Exception => e
  end

  def menu_new_addon_item
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      category = get_addon_category_through_id(params[:addon_category_id])
      if category
        addon = add_new_addon_item(category, params[:item_name].strip, params[:price_per_item].strip, params[:item_name_ar].strip, false, params[:available], params[:include_in_pos], params[:include_in_app], params[:preparation_time])
        @admin = get_admin_user
        restaurant = restaurant
        title = restaurant.title
        msg = "#{title} restaurant has add new addon item"
        type = "add_addon_item"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
      else
        flash[:error] = "Addon category not exists"
      end
      # redirect_to business_menu_item_addon_list_path(menu_item_id: encode_token(category.menu_item.id),branch_id: encode_token(category.menu_item.menu_category.branch.id),restaurant_id: params[:restaurant_id])
      redirect_to business_branch_menu_items_path(id: params[:branch_id], restaurant_id: params[:restaurant_id])
    else
      category = get_addon_category_through_id(params[:addon_category_id])
      if category
        addon = add_new_addon_item(category, params[:item_name].strip, params[:price_per_item].strip, params[:item_name_ar].strip, false, params[:available], params[:include_in_pos], params[:include_in_app], params[:preparation_time])
        @admin = get_admin_user
        restaurant = @user.manager_branches.first.restaurant
        title = restaurant.title
        msg = "#{title} restaurant has add new addon item"
        type = "add_addon_item"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
      else
        flash[:error] = "Addon category not exists"
      end
      redirect_to business_branch_menu_items_path(id: params[:branch_id])
    end

    rescue Exception => e
  end

  def edit_menu_addon_item
    @addon_item = get_addon_item(decode_token(params[:addon_item_id]))
    @branch = get_branch_data(decode_token(params[:branch_id]))
    @addon_categories = @branch.item_addon_categories
    render layout: "partner_application"
  end

  def update_menu_addon_item
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      addon_item = get_addon_item(params[:addon_item_id])
      # @menu_item = get_menu_item(params[:menu_item_id])
      if addon_item
        addonItem = update_addon(addon_item, params[:item_name].strip, params[:price_per_item].strip, params[:addon_category_id].strip, params[:item_name_ar].strip, false, params[:available], params[:include_in_pos], params[:include_in_app], params[:preparation_time])
        @admin = get_admin_user
        restaurant = restaurant
        title = restaurant.title
        msg = "#{title} restaurant has update addon item"
        type = "update_addon_item"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
        addon_item.fill_changed_fields(addon_item.saved_changes.keys)
      else
        flash[:error] = "Addon item not exists"
      end
      # redirect_to business_menu_item_addon_list_path(branch_id: encode_token(@menu_item.menu_category.branch.id),restaurant_id: params[:restaurant_id])
      redirect_to business_branch_menu_items_path(id: params[:branch_id], restaurant_id: params[:restaurant_id])
    else
      addon_item = get_addon_item(params[:addon_item_id])
      if addon_item
        addonItem = update_addon(addon_item, params[:item_name].strip, params[:price_per_item].strip, params[:addon_category_id].strip, params[:item_name_ar], false, params[:available], params[:include_in_pos], params[:include_in_app], params[:preparation_time])
        @admin = get_admin_user
        restaurant = @user.manager_branches.first.restaurant
        title = restaurant.title
        msg = "#{title} restaurant has update addon item"
        type = "update_addon_item"
        send_notification_releted_menu(msg, type, @user, @admin, restaurant.id)
        addon_item.fill_changed_fields(addon_item.saved_changes.keys)
      else
        flash[:error] = "Addon item not exists"
      end
      redirect_to business_branch_menu_items_path(id: params[:branch_id])
    end

    rescue Exception => e
  end

  def remove_menu_addon_item
    addon_item = get_addon_item(params[:id])

    if addon_item
      addon_item.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Addon item does not exists"
      render json: { code: 404 }
    end
  end

  def remove_menu_addon_category
    addon_category = get_addon_category_through_id(params[:id])
    if addon_category
      addon_category.destroy
      render json: { code: 200 }
    else
      flash[:erorr] = "Addon category does not exists"
      render json: { code: 404 }
    end

    rescue Exception => e
  end

  def change_branch_busy_state
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if params[:new_area] == "true"
      new_area_id = params[:area_id]
      @branch_id = params[:branch_id]
      BranchCoverageArea.create(branch_id: @branch_id, coverage_area_id: new_area_id, is_closed: false)
      flash[:success] = "Status updated successfully."
    else
      coverage_area = get_branch_caverage_area(params[:area_id])

      if coverage_area
        email = @user.auths.first.role == "business" ? @user.email : @user.branch_managers.first.branch.restaurant.user.email
        coverage_area.update(is_closed: (params[:is_close].strip.presence || coverage_area.is_close), is_busy: (params[:is_busy].strip.present? ? params[:is_busy] : coverage_area.is_busy), is_active: true, far_menu: (params[:is_far_menu].presence || coverage_area.far_menu))
        send_email_branch_busy_and_close(email, coverage_area)
        flash[:success] = "Status updated successfully."
      end
    end

    redirect_to business_branch_coverage_area_path(branch_id: encode_token(coverage_area&.branch&.id || @branch_id), restaurant_id: params[:restaurant_id])
  end

  def edit_restaurant_details
    @restaurant = get_restaurant_deatils(decode_token(params[:restaurant_id]))
    render layout: "partner_application"
    rescue Exception => e
  end

  def update_restaurant_details
    @restaurant = get_restaurant_deatils(decode_token(params[:restaurant_id]))

    if @restaurant
      update_restaurant(@restaurant, params[:restaurant_logo], @restaurant.title, @restaurant.title_ar, "")

      if @restaurant.title.to_s.strip == params[:restaurant_name].to_s.strip && @restaurant.title_ar.to_s.strip == params[:restaurant_name_ar].to_s.strip
        flash[:success] = "Updated Successfully"
      else
        @restaurant.update(temp_title: params[:restaurant_name].strip, temp_title_ar: params[:restaurant_name_ar].strip, approved: false, rejected: false, name_change_requested_on: Time.zone.now)
        msg = "#{ @restaurant.title } restaurant has requested name change"
        type = "restaurant_name_change"
        send_notification_releted_menu(msg, type, @user, get_admin_user, @restaurant.id)
        flash[:success] = "Restaurant Name Change Request has been sent to Admin!"
      end

      redirect_to business_edit_restaurant_details_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = "Invalid details"
      redirect_to business_restaurant_path(restaurant_id: params[:restaurant_id])
    end

    rescue Exception => e
  end

  def add_daily_dishes
    @branch = get_branch(decode_token(params[:branch_id]))
    @category_text = params[:catering].present? ? "Catering" : "Daily Dishes"
    @category_text_arabic = params[:catering].present? ? "تقديم الطعام" : "أطباق اليوم"
    render layout: "partner_application"
    rescue Exception => e
  end

  def daily_dishes
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    menu_category = find_menu_category_branch(params[:category_title], params[:branch_id])
    @branch = get_branch(params[:branch_id])
    if restaurant
      if !menu_category
        menu_category = add_daily_dishes_category(params[:category_title], params[:category_title_ar], params[:start_date].strip, params[:start_time].strip, params[:branch_id], true, params[:end_time].strip, params[:end_date].strip)
        flash[:success] = "Menu category added successfully"
      else
        menu_category.update(start_date: params[:start_date].strip, end_date: params[:end_date].strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time]).strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time]).strftime("%H:%M"))
        flash[:success] = "Menu category added successfully"
      end
      redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: params[:restaurant_id])
    else
      if !menu_category
        menu_category = add_daily_dishes_category(params[:category_title], params[:category_title_ar], params[:start_date], params[:start_time], params[:branch_id], true, params[:end_time], params[:end_date])
        flash[:success] = "Menu category added successfully"
      else
        menu_category.update(start_date: params[:start_date].strip, end_date: params[:end_date].strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time]).strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time]).strftime("%H:%M"))
        flash[:success] = "Menu category added successfully"
      end
      redirect_to business_branch_menu_items_path(encode_token(@branch.id), restaurant_id: params[:restaurant_id])
    end

    rescue Exception => e
  end

  def edit_daily_dishes
    @branch = get_branch(decode_token(params[:branch_id]))
    @menu_category = get_menu_category(decode_token(params[:category_id]))
    render layout: "partner_application"
    rescue Exception => e
  end

  def update_daily_dishes
    begin
      restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      menu_category = get_menu_category(params[:category_id])
      if restaurant
        if menu_category
          menu_category.update(start_date: params[:start_date].strip, end_date: params[:end_date].strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time]).strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time]).strftime("%H:%M"))
          flash[:success] = "Menu category update successfully."
        else
          flash[:error] = "Menu category not exists"
        end
        redirect_to business_branch_menu_items_path(encode_token(menu_category.branch.id), restaurant_id: params[:restaurant_id])
      else
        if menu_category
          menu_category.update(start_date: params[:start_date].strip, end_date: params[:end_date].strip, start_time: params[:start_date] + " " + DateTime.parse(params[:start_time]).strftime("%H:%M"), end_time: params[:end_date] + " " + DateTime.parse(params[:end_time]).strftime("%H:%M"))
          flash[:success] = "Menu category update successfully."
        else
          flash[:error] = "Menu category not exists"
        end
        redirect_to business_branch_menu_items_path(encode_token(menu_category.branch.id), restaurant_id: params[:restaurant_id])
      end
    end

    rescue Exception => e
  end

  def menu_category_sort
    JSON.parse(params[:category]).each do |category|
      @menu_category = get_menu_category(decode_token(category["category_id"]))
      @menu_category&.update(category_priority: category["index"])
    end
    render json: { code: 200 }
    rescue Exception => e
  end

  def find_area
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id])) rescue nil
    if @user&.auth_role == "business"
      @branches = restaurant.branches.order(:address) rescue nil
      @restaurants = @user.restaurants.map { |r| [r.title, encode_token(r.id)] }.sort rescue nil
    else
      @branches = Branch.where(id: @user.branch_managers.pluck(:branch_id)).order(:address) rescue nil
    end
    @areas = CoverageArea.joins(:branches).where(branches: { id: @branches.pluck(:id) }).distinct.pluck(:area, :id).sort if @branches.present?
  end

  def change_branch_status
    if params[:branch_id].present?
      params[:branch_id].each do |branch|
        @branch = get_branch(branch)
        next unless @branch
        @branch.update(is_busy: params[:status] == "true")
        area = get_branch_active_area(@branch).update_all(is_busy: params[:status] == "true")
        # send_email_branch_busy_and_close(email,coverage_area)
      end
      render json: { code: 200, message: "#{params[:status] == 'true' ? 'Branch busy now' : 'Branch open now'} " }
    else
      render json: { code: 500, message: "Could not process your request" }
    end
  end

  def branch_image_crop
    item_image = upload_multipart_image(params[:item_image], "menu_item", original_filename=nil)
    if item_image.present?
      return render json: {data: item_image, status: 200}
    else
      return render json: {error: "Image not valid", status: 422}
    end
  end
end
