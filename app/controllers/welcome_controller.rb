class WelcomeController < ApplicationController
  before_action :check_user, :check_branch_status
  require "open-uri"
  require "nokogiri"
  require "openssl"

  def index
    @selected_country_id = params[:country_id].present? ? decode_token(params[:country_id]) : (session[:country_id].presence || 15)
    session[:country_id] = @selected_country_id
    @countries = Country.where(id: Restaurant.joins(:branches).where(is_signed: true, branches: { is_approved: true }).pluck(:country_id).uniq).where.not(id: @selected_country_id)
    @country_name = Country.find(@selected_country_id).name
    @categories = Category.where.not(icon: nil, icon: "").order_by_title
    @categories = @categories.where.not(title: "Party") if Point.sellable_restaurant_wise_points(@selected_country_id).empty?
    @areas = CoverageArea.active_areas.where(country_id: @selected_country_id)
    @restaurants = Restaurant.joins(:branches).where(country_id: @selected_country_id, is_signed: true, branches: { is_approved: true }).where.not(title: "").distinct.order(:title).first(7)
  end

  def sitemap
    session[:country_id] ||= 15
    @country = Country.find(decode_token(params[:country_id]))
    @areas = CoverageArea.active_areas.where(country_id: @country.id).order(:area)
    @restaurants = Restaurant.joins(:branches).where(country_id: @country.id, is_signed: true, branches: { is_approved: true }).where.not(title: "").distinct.order(:title)
    @cuisines = Category.order(:title)

    if params[:keyword].present?
      @areas = @areas.where("area like ?", "%#{ params[:keyword].squish }%")
      @cuisines = @cuisines.where("title like ?", "%#{ params[:keyword].squish }%")
      @restaurants = @restaurants.where("title like ?", "%#{ params[:keyword].squish }%")
    end
  end

  def privacy_policies
    if params[:status] == "false"
      render layout: "blank"
    else
      render layout: "application"
    end
  end

  def about_us
    if params[:status] == "false"
      render layout: "blank"
    else
      render layout: "application"
    end
 end

  def contact_us
    if params[:status] == "false"
      render layout: "blank"
    else
      render layout: "application"
    end
  end

  def contact_us_to_admin
    if params[:email] && params[:message] && params[:name]
      Contact.create(email: params[:email], message: params[:message], full_name: params[:name])
      flash[:success] = "Food Club support team will contact you soon"
    else
      flash[:error] = "Parameter Missing!!"
    end
    redirect_back(fallback_location: contact_us_path(status: "false"))
  end

  def mapping_scrape_data
    pageUrl = "http://localhost:3001/restaurants/details"
    doc = HTTParty.get(pageUrl)
    data = doc.parsed_response
    branch = Restaurant.find_by(title: "Sub Corner").branches.first
    # Branch.find_by_id(21363)
    # branch = Restaurant.where("title like (?)","%Jasmi%").first.branches.first
    branch.menu_categories.destroy_all
    data["restaurant"].each do |category|
      match_categories = branch.menu_categories.find_by(category_title: category["title"])
      p "==============================="
      p match_categories
      p "---------------------------------"
      if match_categories.present?
        category["menu_items"].each do |menu_item|
          item = match_categories.menu_items.find_by(item_name: menu_item["title"])
          if item.present?
            p "======================="
            p item
            p "-------------------------"
            if item.item_image.blank?
              begin
                image = Cloudinary::Uploader.upload(menu_item["image"].split("?").first, folder: "menu_item") if menu_item["image"].present?
              rescue Exception => e
                image = nil
              end
              item.update(price_per_item: menu_item["price_per_item"].split("BD").last, item_image: image.present? ? image["secure_url"] : "")
            else
              item.update(price_per_item: menu_item["price_per_item"].split("BD").last)
            end
          else
            match_categories.menu_items.create(item_name: menu_item["title"], item_name_ar: menu_item["title"]["title"], price_per_item: menu_item["price_per_item"].split("BD").last, item_image: image.present? ? image["secure_url"] : "", item_description: menu_item["description"], item_description_ar: menu_item["description"])
          end
        end
      else
        p "un matched"
        @cat = branch.menu_categories.create(category_title: category["title"], categroy_title_ar: category["title"])
        category["menu_items"].each do |menu_item|
          begin
            image = Cloudinary::Uploader.upload(menu_item["image"].split("?").first, folder: "menu_item") if menu_item["image"].present?
          rescue Exception => e
            image = nil
          end

          @item = @cat.menu_items.create(item_name: menu_item["title"], item_name_ar: menu_item["title"]["title"], price_per_item: menu_item["price_per_item"].split("BD").last, item_image: image.present? ? image["secure_url"] : "", item_description: menu_item["description"], item_description_ar: menu_item["description"])
          next if menu_item["item_addon_categories"].blank?
          menu_item["item_addon_categories"].each do |item_addon_category|
            @addon_cat = @item.item_addon_categories.create(addon_category_name: item_addon_category["title"], min_selected_quantity: item_addon_category["min_selected_quantity"], max_selected_quantity: item_addon_category["max_selected_quantity"], addon_category_name_ar: item_addon_category["title"], approve: true)
            item_addon_category["item_addons"].each do |addon_item|
              @addon_cat.item_addons.create(addon_title: addon_item["title"], addon_price: addon_item["price"], addon_title_ar: addon_item["title"], approve: true)
            end
          end
        end
      end
    end
    # restaurant = Restaurant.find_by_title(data["restaurant"]["title"])
    # urldata = Cloudinary::Uploader.upload(data["restaurant"]["logo"],folder: "logos")
    # restaurant.update(logo: urldata["secure_url"])

    send_json_response("Branch list", "success", data)
  end

  def graph_pdf
    user = User.get_user(params[:token])
    @orders = orders_graph_data(user, params[:branch_id])
    p @orders
    @areas = areas_graph_data(user, params[:branch_id])
    @customers = get_customer_data(user, params[:branch_id])
    render layout: "blank"
  end

  def referral
    @user = User.find_by(referral: params[:referral_code])
    render layout: "blank"

    unless @user
      redirect_to "/404.html"
    end
 end

  def submit_referral
    @user = User.find_by(referral: params[:referrer_id])
    if @user && params[:email].present?
      alreadyExists = Referral.where(email: params[:email]).first
      if !alreadyExists
        @user.referrals.create(email: params[:email])
      else
        alreadyExists.update(user_id: @user.id) unless alreadyExists.is_registered
      end
    end
    redirect_to store_redirect(used_device)
  end

  def upload_week_csv
    begin
     file = params[:upload_csv][:file]
     if @admin.class.name =='SuperAdmin'
      country = params[:upload_csv][:country_id]
     else
      country = @admin.class.find(@admin.id)[:country_id]
     end
     @i = 1
     @status = false
     extname = File.extname(file.original_filename)
     if extname == ".csv"
       CSV.foreach(file.path) do |row|
         if @i == 1
           if (row[0] == "Sr. Number") && (row[1] == "Start Date") && (row[2] == "End Date")
             @status = true
           else
             @status = false
             break
           end
         else
           title = row[0]
           start_date = row[1]
           end_date = row[2]
           @weekData = Week.create_week(start_date, end_date, title, country)
           end
         @i += 1
       end
   end
     @status ? flash[:notice] = "Week successfully uploaded!!" : flash[:error] = "Please provide valid csv"
     #redirect_back(fallback_location: root_path)
     redirect_to offers_list_path
   end
   rescue Exception => e
     flash[:error] = "Please provide valid csv"
     #redirect_back(fallback_location: root_path)
     redirect_to offers_list_path
   end

  def upload_restaurant_csv
    # begin
    file = params[:upload_csv][:file]
    @i = 1
    @count = []
    @status = false
    extname = File.extname(file.original_filename)
    if extname == ".csv"
      CSV.foreach(file.path) do |row|
        if @i == 1
          if (row[0] == "Id") && (row[1] == "Title") && (row[2] == "Price Per Item") && (row[3] == "Description") && (row[4] == "Menu Category Id") && (row[6] == "Item Img")
            @status = true
          else
            @status = false
            break
          end
        else
          id = row[0]
          title = row[1]
          price = row[2]
          description = row[3]
          cat_id = row[4]
          image = row[6]
          p id
          p title
          p price
          p description
          p image
          category = MenuCategory.find_by(hs_id: cat_id)
          p category
          # menu_category = MenuCategory.find_by_branch_id(branch.id) if branch
          p id
          if category
            MenuItem.create(item_name: title, price_per_item: price, item_image: image, item_description: description, menu_category_id: category.id, is_available: true, item_name_ar: title, item_description_ar: description, calorie: 0.0, approve: true, hs_id: id)
          end

            # p menu_category
            # if branch
            #   MenuCategory.create(category_title: title, branch_id: branch.id,categroy_title_ar: title,approve: true,hs_id: id)
            # end
            # area = CoverageArea.find_by_area(title.titleize)
            # restaurant = Restaurant.find_by_hs_id(restaurant_id)
            # if area
            #   branch = Branch.create(address: "Ajwad Aljabri Ave, Jurdab, Bahrain", city: "A'ali", zipcode: nil, state: nil, country: "Bahrain", latitude: "26.163836", longitude: "50.571238", restaurant_id: restaurant.id,delivery_time: 60, delivery_charges: "0.5", cash_on_delivery: true, accept_cash: true, accept_card: true, image: "", daily_timing: "8:00AM - 11:30PM", min_order_amount: "2.5", tax_percentage: 0.0,is_favorite: false, is_closed: false, is_busy: false, avg_rating: 4.6, address_ar: "Bahrain", opening_timing: "10:00", closing_timing: "22:00", is_approved: false, hs_id: id)
            #   if branch
            #     BranchCoverageArea.create(delivery_charges: "0", foodclub_charges: nil, minimum_amount: "0", delivery_time: "10", daily_open_at: "12:00AM", daily_closed_at: "12:00AM", is_closed: false, is_busy: false, branch_id: branch.id, coverage_area_id: area.id,cash_on_delivery: true, accept_cash: true, accept_card: true)
            #   end
            # else
            #   cov_area = CoverageArea.create(area: title.titleize, city_id: 1)
            #   if cov_area
            #      branch = Branch.create(address: "Ajwad Aljabri Ave, Jurdab, Bahrain", city: "A'ali", zipcode: nil, state: nil, country: "Bahrain", latitude: "26.163836", longitude: "50.571238", restaurant_id: restaurant.id,delivery_time: 60, delivery_charges: "0.5", cash_on_delivery: true, accept_cash: true, accept_card: true, image: "", daily_timing: "8:00AM - 11:30PM", min_order_amount: "2.5", tax_percentage: 0.0,is_favorite: false, is_closed: false, is_busy: false, avg_rating: 4.6, address_ar: "Bahrain", opening_timing: "10:00", closing_timing: "22:00", is_approved: false, hs_id: id)
            #     if branch
            #       BranchCoverageArea.create(delivery_charges: "0", foodclub_charges: nil, minimum_amount: "0", delivery_time: "10", daily_open_at: "12:00AM", daily_closed_at: "12:00AM", is_closed: false, is_busy: false, branch_id: branch.id, coverage_area_id: cov_area.id,cash_on_delivery: true, accept_cash: true, accept_card: true)
            #     end
            #   end
            # end

            # logo = row[2]
            # cloud_logo = row[3]
            # restaurant = Restaurant.find_by_title(row[1])
            # if restaurant
            #  @count = @count+1
            #  restaurant.update(hs_id: row[0])
            #  p row[0]
            # end
            # image  = cloud_logo.present? ? cloud_logo.include?("cloudinary").present? ? cloud_logo : logo : logo
            # if restaurant
            #   p restaurant
            #   p row[0]
            #   # byebug
            #   if restaurant.title != "Areesh"
            #     restaurant.update(logo: image, hs_id: row[0])
            #   else
            #   end
            # else
            #    p row[0]
            #   rest = Restaurant.create(title: row[1],logo: image,title_ar: row[1], hs_id: row[0])
            #   p rest
            # end
          end
        @i += 1
      end
  end
    @status ? flash[:notice] = "CSV Successfully imported into database" : flash[:error] = "Please provide valid csv"
    redirect_back(fallback_location: root_path)
 end
  # rescue Exception => e
  #   flash[:error] = "Please provide valid csv"
  #   redirect_back(fallback_location: root_path)
  # end

  def scrap_menu
    @restaurant = get_restaurant(decode_token(params[:restaurant_id]))
    if @restaurant
      @restaurant
    end
    render layout: "admin_application"
  end

  def menu_html
    @data = ScrapeMenu.first
    render layout: "blank"
  end

  def scraped_menu_data
    restaurant = get_restaurant(decode_token(params[:restaurant_id]))
    if restaurant
      ScrapMenuThroughTalabatWorker.perform_async(params[:info][:content], decode_token(params[:restaurant_id]))
    end
    redirect_to restaurant_list_path
  end

  def menu_item_image_upload
    @image_url = session[:image_url]
    session.delete(:image_url)
    render layout: "blank"
  end

  def upload_menu_item_image
    image = params[:menu_item_image]
    uploaded_image = image.present? ? upload_multipart_image(image, "menu_item") : nil
    session[:image_url] = uploaded_image
    redirect_to menu_item_image_upload_path
  end

  private

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
    BranchCoverageArea.closing_restaurant_area
    BranchCoverageArea.open_restaurant_area
  rescue ActiveRecord::StatementInvalid => e
  end
end
