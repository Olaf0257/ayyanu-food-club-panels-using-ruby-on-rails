class SuperAdminsController < ApplicationController
  before_action :require_admin_logged_in, :check_branch_status, only: [:dashboard, :edit_password]

  def login
    render layout: "blank"
  end

  def admin_auth
    if params[:email].present? && params[:password].present?
      admin = SuperAdmin.find_by(email: params[:email])
      if admin&.authenticate(params[:password])
        session[:admin_user_id] = admin.id
        #session[:super_user_id] = admin.id
        redirect_to dashboard_path
      elsif
        admin = User.find_by(email: params[:email],is_approved: 1)
        @auth = admin.auths.where("user_id = ?",admin.id).first
        if admin && (@auth ? @auth.valid_password?(params[:password]) : false)
          server_session = @auth.server_sessions.create(server_token: @auth.ensure_authentication_token)
          #session[:admin_user_id] = admin.id
          session[:role_user_id] = admin.id
          redirect_to dashboard_path
        else
          flash[:error] = "Email and password can't be blank"
          redirect_to admin_login_path

        end

      else
        flash[:error] = "Unauthorised Access 1 !!"
        redirect_to admin_login_path
      end
    else
      flash[:error] = "Email and password can't be blank"
      redirect_to admin_login_path
    end
  end

  def dashboard
    if @admin.class.name =='SuperAdmin'
    @user = User.joins(:auths).where("auths.role=?", "customer").count
    @business = User.joins(:auths).where("auths.role=?", "business").count
    @transporter = User.joins(:auths).where("auths.role=?", "transporter").count
    @manager = User.joins(:auths).where("auths.role=?", "manager").count
    @keyword = params[:keyword].presence || "day"
    @close = get_all_close_restaurant.count
    @busy = get_all_busy_restaurant.count
    @graphData = order_graph_data(@keyword)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @user = User.joins(:auths).where(country_id:country_id).where("auths.role=?", "customer").count
      @business = User.joins(:auths).where(country_id:country_id).where("auths.role=?", "business").count
      @transporter = User.joins(:auths).where(country_id:country_id).where("auths.role=?", "transporter").count
      @manager = User.joins(:auths).where(country_id:country_id).where("auths.role=?", "manager").count
      @keyword = params[:keyword].presence || "day"
      @close = get_all_close_restaurant.count
      @busy = get_all_busy_restaurant.count
      @graphData = order_graph_data(@keyword)
    end

    render layout: "admin_application"
  end

  def admin_logout
    session[:admin_user_id] = nil
    session[:role_user_id]  = nil
    flash[:success] = "You successfully signout from Admin Panel !"
    redirect_to admin_login_path
  end

  def uploadDataCsv
    for i in 0..101
      file = File.read("#{Rails.root}/public/jsonData/jsonData-#{i}.json")
      jsonData = JSON.parse(file)
      jsonData.each_with_index do |r, ind|
        # Create Restaurant
        restaurant = Restaurant.find_by(talabat_id: r["restaurant_id"])
        # if !restaurant
        #   restaurant =  Restaurant.create(title: r["restaurant_title"],logo: r["image_logo"], talabat_id: r["restaurant_id"])
        # end

        # Create Branch
        branch = restaurant.branches.find_by(talabat_id: r["branch_id"])
        # if !branch
        #   branch = restaurant.branches.create(city: r["city_name"], latitude: r["latitude"], longitude: r["longitude"], talabat_id: r["branch_id"], delivery_time: r["delivery_time"], delivery_charges: r["delivery_charges"], cash_on_delivery: r["accept_cod"], accept_cash: r["accept_cash"], accept_card: r["accept_credit_card"], image: "#{r['image_baseurl']}#{r['image_name']}", daily_timing: r["daily_timing"], min_order_amount: r["min_order_amount"])
        # end

        # Menu Categories
        next if r["menu"].blank?
        next if r["menu"]["result"].blank?
        next if r["menu"]["result"]["menu"].blank?
        next if r["menu"]["result"]["menu"]["menuSection"].blank?
        begin
          r["menu"]["result"]["menu"]["menuSection"].each do |menu|
            menuCategory = branch.menu_categories.find_by(category_title: menu["nm"])
            # if !menuCategory
            #   menuCategory = branch.menu_categories.create(category_title: menu["nm"])
            # end

            # MenuCategoryItems
            next if menu["itm"].blank?
            menu["itm"].each do |item|
              next unless item["img"] != ""
              menuItem = menuCategory.menu_items.find_by(item_name: item["nm"])
              # if !menuItem
              #   menuItem = menuCategory.menu_items.create(item_name: item["nm"], item_rating: item["rt"], price_per_item: item["pr"], item_image: item["img"], item_description: item["dsc"])
              # end
              p "=============jsonData-#{i}.json  #{ind}"
              menuItem.update(item_image: item["img"])
              # Item Addon Category
              # if item["csc"].present?
              #   item["csc"].each do |itAdCat|
              #     itemAddonCategory = menuItem.item_addon_categories.find_by_addon_category_name(itAdCat["nm"])
              #     if !itemAddonCategory
              #       itemAddonCategory = menuItem.item_addon_categories.create(addon_category_name: itAdCat["nm"], min_selected_quantity: itAdCat["mnq"], max_selected_quantity: itAdCat["mxq"])
              #     end

              #     # Addons
              #     if itAdCat["ich"].present?
              #       itAdCat["ich"].each do |ad|
              #         addon = itemAddonCategory.item_addons.find_by_addon_title(ad["nm"])
              #         if !addon
              #           addon = itemAddonCategory.item_addons.create(addon_title: ad["nm"], addon_price: ad["pr"])
              #         end
              #       end
              #       end

              #   end
              # end
            end
          end
        rescue Exception => e
          p "XXXXXXX #{e}"
          # need specify which file is running and which restaurant_id
        end
      end
    end
    @result = "done"
  end

  def uploadLogoJson
    file = File.read("#{Rails.root}/public/jsonLogoData.json")
    jsonData = JSON.parse(file)
    jsonData.each do |r|
      res = Restaurant.find_by(logo: r["image_name"])
      if res
        res.update(logo: r["cloud_url"])
      else
        p "===xxxxxx === Not found === #{r['image_name']}"
      end
    end
  end

  def uploadItemImageJson
    file = File.read("#{Rails.root}/public/jsonItemImgData.json")
    jsonData = JSON.parse(file)
    jsonData.each_with_index do |r, findx|
      next unless r["image_name"] != ""
      totalItems = MenuItem.where(item_image: r["image_name"]).where.not("item_image LIKE ?", "%cloudinary%").count
      p "===#{findx} total Item(s) : #{totalItems}"
      if totalItems > 1
        itemImages = [r["cloud_url"]]
        for i in 1...totalItems
          p i
          urldata = Cloudinary::Uploader.upload("#{Rails.root}/public/itemsImgs/#{r['cloud_url'].split('/').last}", folder: "items")
          begin
             File.open("public/imgs/#{urldata['secure_url'].split('/').last}", "wb") do |fo|
               fo.write open(urldata["secure_url"]).read
             end
           rescue Exception => e
             p "xxxxxxxxxxxxx"
             p e
             p "--------------"
           end
          itemImages << urldata["secure_url"]
          p "url ==== #{urldata['secure_url']}"
        end
        MenuItem.where(item_image: r["image_name"]).where.not("item_image LIKE ?", "%cloudinary%").each_with_index do |img, indx|
          img.update(item_image: itemImages[indx])
          p "===#{indx + 1}/#{totalItems}"
        end
      elsif totalItems == 1
        MenuItem.find_by(item_image: r["image_name"]).update(item_image: r["cloud_url"])
      else
        p "Item not found for #{r['image_name']}"
      end
    end
  end

  def uploadFastImg
    file = File.read("#{Rails.root}/public/jsonItemImgData.json")
    jsonData = JSON.parse(file)
    jsonData.each_with_index do |r, _findx|
      next unless r["image_name"] != ""
      totalItems = MenuItem.where(item_image: r["image_name"]).where.not("item_image LIKE ?", "%cloudinary%").count
      if totalItems >= 1
        MenuItem.where(item_image: r["image_name"]).where.not("item_image LIKE ?", "%cloudinary%").update_all(item_image: r["cloud_url"])
      end
    end
  end

  def edit_password
    @user = @admin
    render layout: "admin_application"
  end

  def reset_password
    @user = SuperAdmin.exists?(params[:user_id]) ? SuperAdmin.first : find_user(params[:user_id])

    if @user
      if is_super_admin?(@user)
        if @user.authenticate(params[:old_password])
          @user.update(password: params[:new_password])
          responce_json(code: 200, message: "Password changed successfully")
        else
          responce_json(code: 404, message: "Old password doesn't match")
        end
      else
        auth = @user.auths.first
        if auth.valid_password?(params[:old_password])
          auth.update(password: params[:new_password])
          responce_json(code: 200, message: "Password changed successfully")
        else
          responce_json(code: 404, message: "Old password doesn't match")
        end
      end
    end
  end


  private

  def check_branch_status
    Branch.closing_restaurant
    Branch.open_restaurant
  rescue ActiveRecord::StatementInvalid => e
  end
end
