module EnterprisesHelper
  require "dropbox"
  def add_enterprise_request(restaurant_name, restaurant_id, person_name, contact_number, role, email, area, cuisine, cr_number, bank_name, bank_account, _images, _signature, cpr_number, owner_name, nationality, submitted_by, delivery_status, branch_no, mother_company_name, serving, block, road_number, building, unit_number, floor, other_name, other_role, other_email,country_id)
    restaurant = Enterprise.create_restaurant_request_details(restaurant_name, restaurant_id, person_name, contact_number, role, email, area, cuisine, cr_number, bank_name, bank_account, cpr_number, owner_name, nationality, submitted_by, delivery_status, branch_no, mother_company_name, serving, block, road_number, building, unit_number, floor, other_name, other_role, other_email, country_id)
    begin
      if restaurant.id.present? && params[:images].present?
        app_key = "gf3h7ccuo7pvhm3"
        app_secret = "ab35tygk5uz1xnx"
        dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ")
        file = open(params[:images])
        file_name = params[:images].original_filename
        file = dbx.upload("/#{Time.now.to_i}#{file_name}", file)
        result = HTTParty.post("https://api.dropboxapi.com/2/sharing/create_shared_link",
                               body: { path: file.path_display }.to_json,
                               headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ", "Content-Type" => "application/json" })
        EnterpriseImage.create(url: result.parsed_response["url"], new_restaurant_id: restaurant.id, doc_type: "Cr  Document")
        upload_signature_on_dropbox(restaurant)
       end
    rescue Exception => e
    end
    restaurant
  end

  def upload_signature_on_dropbox(restaurant)
    app_key =  "gf3h7ccuo7pvhm3"
    app_secret = "ab35tygk5uz1xnx"
    dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ")
    file = open(params[:signature])
    file_name = params[:signature].original_filename
    file = dbx.upload("/#{Time.now.to_i}#{file_name}", file)
    result = HTTParty.post("https://api.dropboxapi.com/2/sharing/create_shared_link",
                           body: { path: file.path_display }.to_json,
                           headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ", "Content-Type" => "application/json" })
    EnterpriseImage.create(url: result.parsed_response["url"], new_restaurant_id: restaurant.id, doc_type: "Signature")
    rescue Exception => e
  end

  def get_branch(branch_id)
    Branch.find_branch(branch_id)
  end

  def get_branch_active_area(branch)
    branch.branch_coverage_areas.where(is_active: true)
  end

  def get_restaurant_all_branch(restaurant_id)
    Restaurant.find_restaurant(restaurant_id)
  end

  def find_menu_category_by_branch(branch_id)
    MenuCategory.findMenuCategoryByBranch(branch_id)
  end

  def find_menu_category_branch(category_title, branch_id)
    MenuCategory.findMenuCategoryBranch(category_title, branch_id)
  end

  def get_admin_user
    SuperAdmin.first
  end

  def find_menu_category_id_branch(category_id, branch_id)
    MenuCategory.findMenuCategoryIdBranch(category_id, branch_id)
  end

  def new_menu_category(category_title, category_title_ar, branch_id, approve, available)
    MenuCategory.newMenuCategory(category_title, category_title_ar, branch_id, approve, available)
  end

  def add_daily_dishes_category(category_title, category_title_ar, start_date, start_time, branch_id, approve, end_time, end_date)
    MenuCategory.create(category_title: category_title, categroy_title_ar: category_title_ar, branch_id: branch_id, approve: approve, start_date: start_date, end_date: end_date, start_time: start_date + " " + DateTime.parse(start_time).strftime("%H:%M"), end_time: end_date + " " + DateTime.parse(end_time).strftime("%H:%M"))
  end

  def get_menu_category(category_id)
    MenuCategory.find_by(id: category_id)
  end

  def is_update_menu_category(category, category_title, category_title_ar, branch_id, category_priority, available)
    MenuCategory.updateMenuCategory(category, category_title, category_title_ar, branch_id, category_priority, available)
  end

  def get_menu_id_catId(menu_item_id, _menu_category_id)
    MenuItem.find_by(id: menu_item_id)
  end

  def get_menu_item_name_catId(item_name, menu_category_id)
    MenuItem.find_menu_item_name_catId(item_name, menu_category_id)
  end

  def is_new_menu_item(item_name, price_per_item, item_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu)
    image = item_image.present? ? upload_multipart_image(item_image, "menu_item") : nil
    MenuItem.newMenuItem(item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu)
  end

  def is_update_menu_item(item, item_name, price_per_item, new_item_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, item_date, addon_category_id, far_menu, menu_item_ids)
    prev_img = item.item_image.present? ? item.item_image.split("/").last.split(".")[0] : "n/a"
    image = new_item_image.present? ? update_multipart_image(prev_img, new_item_image, "menu_item") : item.item_image.presence
    menu = MenuItem.updateMenuItem(item, item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, far_menu, menu_item_ids)
    add_daily_dishes_date(item_date, item) if item_date.present?
    create_add_on(addon_category_id, item)
  end

  def add_daily_dishes_date(date, item)
    dish_date = date.to_s.delete!('"')[1..-2].split(",").collect { |car| car.strip.tr("'", "") }
    delete_dish_date(dish_date, item)
    dish_date.each do |date|
      item.menu_item_dates.find_or_create_by(menu_date: date.to_date)
    end
  end

  def create_add_on(addon_category_id, item)
    delete_addon(item, addon_category_id)
    if addon_category_id.present?
      addon_category_id.each do |addon_id|
        item.menu_item_addon_categories.find_or_create_by(item_addon_category_id: addon_id)
      end
    end
  end

  def delete_dish_date(dish_date, item)
    if dish_date.present?
      item.menu_item_dates.where("DATE(menu_date) >= (?)", Date.today).each do |date|
        unless dish_date.include? date.menu_date.strftime("%Y-%m-%d")
          date.destroy
        end
      end
      # dish_date
    else
      item.menu_item_dates.destroy_all
    end
  end

  def delete_addon(item, addon_ids)
    if addon_ids.present?
      addon = item.item_addon_categories.pluck(:id) - addon_ids.map(&:to_i)
      addon.each do |addon_id|
        menu_addon = MenuItemAddonCategory.find_by(item_addon_category_id: addon_id, menu_item_id: item.id)
        menu_addon.destroy
      end
    else
      item.menu_item_addon_categories.destroy_all
    end
  end

  def get_restaurant(restaurant_id)
    Restaurant.find_by(id: restaurant_id)
  end

  def get_request_restaurant(restaurant_id)
    Enterprise.find_new_restaurant(restaurant_id)
  end

  def get_restaurant_doc(doc_id)
    EnterpriseImage.find_by(id: doc_id)
  end

  def update_restaurant_data(req_restaurant)
    data = req_restaurant.update(is_approved: true)

    if data
      password = SecureRandom.hex(5)
      user = User.create_restaurant_owner(req_restaurant)

      if user[:code] == 200
        auth = Auth.create_user_password(user[:result], password, "business")
        user[:result].reload.save
        req_restaurant.update(user_id: user[:result].id)

        if req_restaurant.restaurant.present?
          req_restaurant.restaurant.update(user_id: user[:result].id, country_id: req_restaurant.country_id)
        else
          # restaurant = Enterprise.create_restaurant(req_restaurant, user)
        end

        # send_email_on_restaurant_owner(req_restaurant.email, req_restaurant.owner_name, password)
      end
    end
  end

  def create_delivery_company_user(company)
    if company.present?
      password = SecureRandom.hex(5)
      user = User.create_delivery_company_person(company)

      if user[:code] == 200
        auth = Auth.create_delivery_company_user_password(user[:result], password, "delivery_company")
        user[:result].reload.save
        DeliveryCompanyWorker.perform_async(company.email, company.name, password, "approved")
      end
    end
  end

  def get_restaurant_data(restaurant_id)
    Restaurant.find_by(id: restaurant_id)
  end

  def get_user_details(user_id)
    User.find_by(id: user_id)
  end

  def send_email_on_restaurant_owner(email, name, password)
    RestaurantMailer.send_email_on_restaurant_owner_with_loginId(email, name, password).deliver_now
    rescue Exception => e
  end

  def update_restaurant_reject_data(req_restaurant, reject_reason)
    data = req_restaurant.update(is_rejected: true, reject_reason: reject_reason, rejected_at: Time.zone.now)
    if data
      begin
        RestaurantMailer.send_email_to_restaurant(req_restaurant).deliver_now
      rescue Exception => e
      end
    end
  end

  def addon_category_add(branch, addon_category_name, addon_category_name_ar, min_selected_quantity, max_selected_quantity, approve, available)
    ItemAddonCategory.create_new_addon_category(branch, addon_category_name, addon_category_name_ar, min_selected_quantity, max_selected_quantity, approve, available)
  end

  def get_addon_category(category_name, menu_item_id)
    ItemAddonCategory.find_by(addon_category_name: category_name, menu_item_id: menu_item_id)
  end

  def get_branch_addon_category(category_name, branch_id)
    ItemAddonCategory.find_by(addon_category_name: category_name, branch_id: branch_id)
  end

  def get_addon_category_through_id(category_id)
    ItemAddonCategory.find_by(id: category_id)
  end

  def add_new_addon_item(category, item_name, price_per_item, item_name_ar, approve, available)
    ItemAddon.create_new_addon_item(category, item_name, price_per_item, item_name_ar, approve, available)
  end

  def get_addon_item(item_id)
    ItemAddon.find_by(id: item_id)
  end

  def update_addon(addon_item, item_name, price_per_item, addon_category_id, item_name_ar, approve, available)
    addon_item.update(addon_title: item_name, addon_price: price_per_item, item_addon_category_id: addon_category_id, addon_title_ar: item_name_ar, approve: approve, is_rejected: false, available: available)
  end

  def send_email_to_foodclube(business_user, title, msg)
    UserMailer.send_email_new_menu_item(business_user, title, msg).deliver_now
    rescue Exception => e
  end

  def get_menu_data(status, _page, _per_page, restaurant)
    case status
    when "addon_category"
      ItemAddonCategory.includes(menu_items: :menu_category).where("approve = ? and branch_id IN (?) ", false, restaurant.branches.pluck(:id)).order(id: :desc)
    when "menu_item"
      MenuItem.includes(menu_category: :branch).joins(menu_category: [{ branch: :restaurant }]).where("menu_items.approve = ? and restaurant_id = ? ", false, restaurant.id).order(id: :desc)
    when "addon_item"
      ItemAddon.includes(:item_addon_category).joins(:item_addon_category).where("item_addons.approve = ? and branch_id IN (?)", false, restaurant.branches.pluck(:id)).order(id: :desc)
    else
      MenuCategory.includes(branch: :restaurant).joins(branch: :restaurant).where("approve = ? and restaurant_id = ? ", false, restaurant.id).order(id: :desc)
    end
  end

  def get_menu_data_status(status, item_id)
    data = case status
           when "addon_category"
             ItemAddonCategory.find_by(id: item_id)
           when "menu_item"
             MenuItem.find_by(id: item_id)
           when "addon_item"
             ItemAddon.find_by(id: item_id)
           else
             MenuCategory.find_by(id: item_id)
           end
  end

  def send_notification_to_business(status, data, admin, type)
    case status
    when "addon_category"
      p type
      branch_id = data.branch.id
      restaurant_id = data.branch.restaurant
      msg = ["Approved", "Bulk Approved"].include?(type) ? "#{data.addon_category_name} Addon Category Approved" : "#{data.addon_category_name} Addon Category Rejected: " + data.resion.to_s
      notify_to_business(branch_id, restaurant_id, admin, msg, "addon_category", type)
    when "menu_item"
      branch_id = data.menu_category.branch.id
      restaurant_id = data.menu_category.branch.restaurant
      msg = ["Approved", "Bulk Approved"].include?(type) ? "#{data.item_name} Menu Item Approved" : "#{data.item_name} Menu Item Rejected: " + data.resion.to_s
      notify_to_business(branch_id, restaurant_id, admin, msg, "menu_item", type)
    when "addon_item"
      branch_id = data.item_addon_category.branch.id
      restaurant_id = data.item_addon_category.branch.restaurant
      msg = ["Approved", "Bulk Approved"].include?(type) ? "#{data.addon_title} Addon Item Approved" : "#{data.addon_title} Addon Item Rejected: " + data.resion.to_s
      notify_to_business(branch_id, restaurant_id, admin, msg, "addon_item", type)
    else
      branch_id = data.branch.id
      restaurant_id = data.branch.restaurant
      msg = ["Approved", "Bulk Approved"].include?(type) ? "#{data.category_title} Menu Category Approved" : "#{data.category_title} Menu Category Rejected: " + data.resion.to_s
      notify_to_business(branch_id, restaurant_id, admin, msg, "menu_category", type)
    end
  end

  def send_menu_approval_email(data); end

  def send_notification_releted_menu(msg, notification_type, user, admin, restaurant_id)
    # p Rails.application.configuration[Rails.env.to_sym][:pusher][:app_id]

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
    noti = Notification.create(message: msg, notification_type: notification_type, user_id: user.present? ? user.id : "", admin_id: admin.id, restaurant_id: restaurant_id)
  rescue StandardError
  end

  def send_amount_settle_notification_to_admin(msg, notification_type, user, admin, company_id)
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )
    pusher_client.trigger("my-channel", "my-event", { })
    noti = Notification.create(message: msg, notification_type: notification_type, user_id: user.id, admin_id: admin.id, delivery_company_id: company_id)
  rescue StandardError
  end

  def send_pending_order_notification_to_admin(msg, notification_type, user, admin, company_id)
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )
    pusher_client.trigger("my-channel", "my-event", { })
    noti = Notification.create(message: msg, notification_type: notification_type, user_id: user.id, admin_id: admin.id, delivery_company_id: company_id)
  rescue StandardError
  end

  def notify_to_business(branch_id, restaurant, admin, msg, type, menu_status)
    unless menu_status == "Bulk Approved" || menu_status == "Bulk Rejected"
      @webPusher = web_pusher(Rails.env)
      pusher_client = Pusher::Client.new(
        app_id: @webPusher[:app_id],
        key: @webPusher[:key],
        secret: @webPusher[:secret],
        cluster: "ap2",
        encrypted: true
      )

      # channelName = "public-branch" + branch_id.to_s # for branch managers
      # pusher_client.trigger(channelName, "my-event", root: channelName)

      channelName = "public-restaurant" + restaurant.user.id.to_s # for restaurant owner
      pusher_client.trigger(channelName, "my-event", root: channelName)
    end

    noti = Notification.create(message: msg, notification_type: type, receiver_id: restaurant.user.id, admin_id: admin.id, menu_status: menu_status)
  rescue StandardError
  end

  def bulk_notify_to_business(branch_id, restaurant)
    @webPusher = web_pusher(Rails.env)
    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    # channelName = "public-branch" + branch_id.to_s # for branch managers
    # pusher_client.trigger(channelName, "my-event", root: channelName)

    channelName = "public-restaurant" + restaurant.user.id.to_s # for restaurant owner
    pusher_client.trigger(channelName, "my-event", root: channelName)
  rescue StandardError
  end

  def add_area(delivery_charges, minimum_amount, delivery_time, daily_open_at, daily_closed_at, branch_id, coverage_area_id, cash_on_delivery, accept_cash, accept_card)
    BranchCoverageArea.add_branch_area(delivery_charges, minimum_amount, delivery_time, daily_open_at, daily_closed_at, branch_id, coverage_area_id, cash_on_delivery, accept_cash, accept_card)
  end

  def get_all_close_restaurant
    if @admin.class.name == "SuperAdmin"
      BranchCoverageArea.joins(:coverage_area, branch: :restaurant).where("branch_coverage_areas.is_closed = ?", true)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      BranchCoverageArea.joins(:coverage_area, branch: :restaurant).where("branch_coverage_areas.is_closed = ?", true).where("restaurants.country_id = ?", country_id)
    end
  end

  def get_all_busy_restaurant
    if @admin.class.name == "SuperAdmin"
      BranchCoverageArea.joins(:coverage_area, branch: :restaurant).where("branch_coverage_areas.is_busy = ?", true)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      BranchCoverageArea.joins(:coverage_area, branch: :restaurant).where("branch_coverage_areas.is_busy = ?", true).where("restaurants.country_id = ?", country_id)
    end
  end

  def update_influencer_coupon_restaurants(coupon)
    coupon.influencer_coupon_branches.destroy_all
    coupon.influencer_coupon_menu_items.destroy_all

    if params[:all_restaurants].blank?
      params.select { |k, _v| k.include?("restaurant_id") }.each do |k, v|
        count = k.split("_")[2]
        restaurant_id = params["restaurant_id_" + count]
        branch_ids = params["branch_ids_" + count].to_a.reject(&:blank?)
        category_ids = params["category_ids_" + count].to_a.reject(&:blank?)
        item_ids = params["item_ids_" + count].to_a.reject(&:blank?)

        if item_ids.present?
          item_ids.each do |item_id|
            InfluencerCouponMenuItem.create(influencer_coupon_id: coupon.id, menu_item_id: item_id)
          end
        elsif category_ids.present?
          category_ids.each do |category_id|
            category_items = MenuItem.where(menu_category_id: category_id)

            category_items.each do |item|
              InfluencerCouponMenuItem.create(influencer_coupon_id: coupon.id, menu_item_id: item.id)
            end
          end
        end

        if branch_ids.present?
          branch_ids.each do |branch_id|
            InfluencerCouponBranch.create(influencer_coupon_id: coupon.id, branch_id: branch_id)
          end
        elsif restaurant_id.present?
          Restaurant.find(restaurant_id).branches.each do |branch|
            InfluencerCouponBranch.create(influencer_coupon_id: coupon.id, branch_id: branch.id)
          end
        end
      end
    end
  end

  def update_referral_coupon_restaurants(coupon)
    coupon.referral_coupon_branches.destroy_all
    coupon.referral_coupon_menu_items.destroy_all

    if params[:all_restaurants].blank?
      params.select { |k, _v| k.include?("restaurant_id") }.each do |k, v|
        count = k.split("_")[2]
        restaurant_id = params["restaurant_id_" + count]
        branch_ids = params["branch_ids_" + count].to_a.reject(&:blank?)
        category_ids = params["category_ids_" + count].to_a.reject(&:blank?)
        item_ids = params["item_ids_" + count].to_a.reject(&:blank?)

        if item_ids.present?
          item_ids.each do |item_id|
            ReferralCouponMenuItem.create(referral_coupon_id: coupon.id, menu_item_id: item_id)
          end
        elsif category_ids.present?
          category_ids.each do |category_id|
            category_items = MenuItem.where(menu_category_id: category_id)

            category_items.each do |item|
              ReferralCouponMenuItem.create(referral_coupon_id: coupon.id, menu_item_id: item.id)
            end
          end
        end

        if branch_ids.present?
          branch_ids.each do |branch_id|
            ReferralCouponBranch.create(referral_coupon_id: coupon.id, branch_id: branch_id)
          end
        elsif restaurant_id.present?
          Restaurant.find(restaurant_id).branches.each do |branch|
            ReferralCouponBranch.create(referral_coupon_id: coupon.id, branch_id: branch.id)
          end
        end
      end
    end
  end

  def update_restaurant_coupon_restaurants(coupon)
    coupon.restaurant_coupon_branches.destroy_all
    coupon.restaurant_coupon_menu_items.destroy_all

    if params[:all_restaurants].blank?
      params.select { |k, _v| k.include?("restaurant_id") }.each do |k, v|
        count = k.split("_")[2]
        restaurant_id = params["restaurant_id_" + count]
        branch_ids = params["branch_ids_" + count].to_a.reject(&:blank?)
        category_ids = params["category_ids_" + count].to_a.reject(&:blank?)
        item_ids = params["item_ids_" + count].to_a.reject(&:blank?)

        if item_ids.present?
          item_ids.each do |item_id|
            RestaurantCouponMenuItem.create(restaurant_coupon_id: coupon.id, menu_item_id: item_id)
          end
        elsif category_ids.present?
          category_ids.each do |category_id|
            category_items = MenuItem.where(menu_category_id: category_id)

            category_items.each do |item|
              RestaurantCouponMenuItem.create(restaurant_coupon_id: coupon.id, menu_item_id: item.id)
            end
          end
        end

        if branch_ids.present?
          branch_ids.each do |branch_id|
            RestaurantCouponBranch.create(restaurant_coupon_id: coupon.id, branch_id: branch_id)
          end
        elsif restaurant_id.present?
          Restaurant.find(restaurant_id).branches.each do |branch|
            RestaurantCouponBranch.create(restaurant_coupon_id: coupon.id, branch_id: branch.id)
          end
        end
      end
    end
  end
end
