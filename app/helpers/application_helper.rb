module ApplicationHelper
  include ActionView::Helpers::DateHelper
  include Preventapi
  include RestaurantsHelper
  include OrdersHelper
  include CategoriesHelper
  include Business::OrdersHelper
  include Business::UsersHelper
  include Business::BranchesHelper
  include Business::PartnersHelper
  include Business::OffersHelper
  include UsersHelper
  include SuperAdminsHelper
  include OffersHelper
  include WelcomeHelper
  include Business::ReportsHelper
  include Business::NotificationsHelper
  include ClubesHelper
  include DocumentsHelper
  include Business::BudgetsHelper
  include Business::IousHelper
  include ReviewsHelper
  include NotificationsHelper
  include Api::Web::UsersHelper
  include AreasHelper
  include AppsettingsHelper
  include ActionView::Helpers::NumberHelper

  def is_active_controller(controller_name)
    (params[:controller] == controller_name && params[:action].to_s != "event_calendar") ? "active" : nil
  end

  def total_due_pos_payment(pos_check)
    total_pos_transaction = pos_check.pos_transactions.pluck(:total_amount).sum
    @tax = Tax.where(country_id: pos_check&.branch&.restaurant&.country_id).pluck(:percentage).sum
    total_pos_payments = pos_check.pos_payments.where(pending_delete: false).pluck(:paid_amount).sum
    @discount = 0.0
    payment = pos_check.pos_payments.find_by payment_method_id: 4
    if pos_check.offer.present? && pos_check.offer.menu_item_id.present? 
      addons = ItemAddon.where(item_addon_category_id: pos_check.offer.menu_item.item_addon_categories.pluck(:id))  
      total_ind_amount = pos_check.pos_transactions.where(
        '(itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?))', 
        "MenuItem", pos_check&.offer&.menu_item_id, "ItemAddon", addons.pluck(:id) )&.pluck(:total_amount)&.sum.to_f 
    else 
      total_ind_amount = 0.0 
    end 
    tax_amount = taxonlyamount(@tax, pos_check.pos_transactions.pluck(:total_amount).sum)
    offer_text = pos_check.offer.present? ? pos_check.offer.discount_percentage.to_f == 0.0 ? pos_check.offer.offer_title : pos_check.offer.discount_percentage.to_s + "%"  : nil 
    discount_per = pos_check.offer.present? ? pos_check.offer.discount_percentage.to_f == 0.0 && pos_check.offer.offer_title.eql?('Buy 1 Get 1 Free') ? 50 : pos_check.offer.discount_percentage.to_f : 0.0 
    transaction_total = pos_check.pos_transactions.pluck(:total_amount).sum.to_f 
    individual_tax = pos_check&.offer&.offer_type.eql?('individual')  ? taxonlyamount(@tax, total_ind_amount) : 0.0 
    @discount =  pos_check.offer_id.present? ? pos_check.offer.offer_type.eql?('individual') ? ((pos_check.is_full_discount ? total_ind_amount : (total_ind_amount - individual_tax.to_f))  * discount_per / 100) : pos_check.pos_transactions.length > 0 ? ((pos_check.is_full_discount ? transaction_total : (transaction_total - tax_amount.to_f)) * (discount_per) / 100) : 0 : 0 
    number_with_precision((total_pos_transaction - total_pos_payments - @discount), precision: 3)
  end

  def is_active_order_controller(controller_name)
    (params[:controller] == controller_name && (params[:action].to_s != "event_calendar" && params[:action].to_s != 'show' && params[:action].to_s != 'order_invoice')) ? "active" : nil
  end

  def is_active_customer(action_name)
    (params[:action] == action_name || params[:is_view_address] == 'true') ? "active" : nil
  end

  def set_time_formated(created_at)
    created_at.strftime("%d-%m-%Y %I:%M %p")
  end

  def totalCategoryAddonCount(pos_transaction)
    pos_transaction&.parent_pos_transaction&.itemable&.item_addon_categories&.length.to_i
  end

  def getCategoryWithCountHash(pos_transaction)
    if pos_transaction.parent_pos_transaction.present?
      pos_transaction.parent_pos_transaction.addon_pos_transactions.group_by { |a| a.itemable.item_addon_category_id }.map { |k,v| [k, v.count] }.to_h
    else
      pos_transaction.itemable.item_addon_categories.map { |a| [a.id, pos_transaction.addon_pos_transactions.length] if  pos_transaction.addon_pos_transactions.length < a.max_selected_quantity.to_i  }.compact.to_h
    end
  end

  def check_guest_type(noOfGuest)
    noOfGuest.to_i == noOfGuest ? noOfGuest.to_i : noOfGuest
  end

  def tableCount(posTable, posCheck)
    pos_checks = posTable ? posTable.pos_checks.where(order_type_id: 1).where.not(check_status: 'closed').order(:created_at) : ''
    if pos_checks.present?
      pos_index = pos_checks.index(posCheck)
    end
    pos_index ? pos_index + 1 : ''
  end

  def taxamount(tax, before_tax_amount)
    tax_amount = taxonlyamount(tax, before_tax_amount)
    number_with_precision(tax_amount, precision: 3)
  end

  def taxonlyamount(tax, before_tax_amount)
    before_tax_amount - ((100 * before_tax_amount) / (100 + 5)).to_f
  end

  def getComment(addon, tableId)
    addon.pos_transactions.where(pos_table_id: tableId).last.try(:comments)
  end

  def getCurrentCount(addonCategory, tableId, menuItemId)
    pos_transactions = PosTransaction.where(pos_table_id: tableId).where.not(parent_pos_transaction_id: nil)
    pos_transactions.select { |a| a.parent_pos_transaction.present? && a.parent_pos_transaction.itemable_id == menuItemId.to_i && a.itemable.item_addon_category_id == addonCategory.id }.map(&:qty).sum
  end

  def before_tax_amount(tax, before_tax_amount)
   tax_amount = taxonlyamount(tax, before_tax_amount)
   after_tax = before_tax_amount - tax_amount
   number_with_precision(after_tax, precision: 3)
  end

  def get_tax_amount(pos_check)
    Tax.where(country_id: pos_check&.branch&.restaurant&.country_id).pluck(:percentage).sum
  end

  def check_offer_text(pos_check)
    pos_check.offer.present? ?
      pos_check.offer.discount_percentage.to_f == 0.0 ?
        pos_check.offer.offer_title :
        pos_check.offer.discount_percentage.to_s + "%" :
        nil
  end

  def discount_per(pos_check)
    pos_check.offer.present? ?
      pos_check.offer.discount_percentage.to_f == 0.0 && @pos_check.offer.offer_title.eql?('Buy 1 Get 1 Free') ?
      50 :
      pos_check.offer.discount_percentage.to_f :
      0.0 
  end

  def total_transaction_amount(pos_check)
    pos_check.pos_transactions.pluck(:total_amount).sum
  end

  def get_discount(pos_check, discount_per, tax)
    offer = pos_check.offer
    if offer.present? && pos_check.pos_transactions.length > 0
      if offer.menu_item_id.present?
        addons = ItemAddon.where(item_addon_category_id: offer.menu_item.item_addon_categories.pluck(:id))
        total_ind_amount = pos_check.pos_transactions.where(
          '(itemable_type = ? && itemable_id = ?) || (itemable_type = ? && itemable_id IN (?))', 
          "MenuItem", offer&.menu_item_id, "ItemAddon", addons.pluck(:id) )&.pluck(:total_amount)&.sum.to_f
      else
        total_ind_amount = pos_check.pos_transactions&.pluck(:total_amount)&.sum.to_f
      end
      individual_tax =  taxonlyamount(tax, total_ind_amount) 
      amount = pos_check.is_full_discount ? total_ind_amount : (total_ind_amount - individual_tax.to_f)
      discount_amount = (amount * discount_per) / 100
    else
      discount_amount = 0.0
    end
    discount_amount
  end

  def google_map_javascript_api
    "AIzaSyACAG0hdhzYNaX80y68Fsn2D5-jQnSGm-Q"
  end

  def web_pusher(env)
    case env
    when "production"
      { app_id: "561959", key: "e9be41db8225a0ad8e7f", secret: "d37ff685fc5feeb6bcb5" }
    else
      { app_id: "910326", key: "c484e921b5dcec12b06e", secret: "2bcd3b146887a0933c98" }
    end
  end

  def fetch_order_status(pos_checks)
    data = {
      check_id: [],
      order_type:[],
      driver: [],
      status: {},
      amount: {},
      table_no: {}
    }
    pos_checks.each do |pos_check|
      data[:check_id].push(pos_check&.check_id)
      data[:order_type].push([pos_check.order_type.name, pos_check.order_type_id])
      data[:driver].push([pos_check.driver.name, pos_check.driver_id]) if pos_check.driver_id.present?
      if pos_check.order.present?
        data[:status][pos_check.order.current_status].present? ?
          data[:status][pos_check.order.current_status].push(pos_check.id) :
          data[:status][pos_check.order.current_status] = [pos_check.id]
      end
      amount = number_with_precision(pos_check.pos_transactions.pluck(:total_amount)&.sum&.to_f, precision: 3)
      data[:amount][amount].present? ?
        data[:amount][amount].push(pos_check.id) :
        data[:amount][amount] = [pos_check.id]
      if pos_check.pos_table_id.present? && pos_check&.order_type_id == 1
        data[:table_no][pos_check&.pos_table&.pos_table_no].present? ?
          data[:table_no][pos_check&.pos_table&.pos_table_no].push(pos_check&.id) :
          data[:table_no][pos_check&.pos_table&.pos_table_no] = [pos_check&.id]
      end
    end
    data
  end

  # def

  # pusher key production Server
  # app_id = "910327"
  # key = "c0151ff3c959f1fe978b"
  # secret = "fa8ce64717c9f12e3d45"
  # cluster = "ap2"
  # pusher key staging server
  # app_id = "910326"
  # key = "c484e921b5dcec12b06e"
  # secret = "2bcd3b146887a0933c98"
  # cluster = "ap2"

  def is_active_action(action_name)
    params[:action] == action_name ? "active" : nil
  end

  def is_active_setup_master
    [ "advertisement_list", "add_advertisement", "pending_advertisement_list", "offer_list", "add_offer", "update_offer"].include?(params[:action]) ? 'active' : ''
  end

  def admin_log_in?
    #@admin = SuperAdmin.find(session[:admin_user_id]) if session[:admin_user_id].present?
    if session[:admin_user_id].present?
      @admin = SuperAdmin.find(session[:admin_user_id])
    else
      if session[:role_user_id].present?
      @admin = User.find(session[:role_user_id])
      @roles = Role.where(id: @admin.role_id)
    end
    end
  end

  def check_user
    if session[:admin_user_id].present?
      @admin = SuperAdmin.find(session[:admin_user_id])
    else
      if session[:role_user_id].present?
      @admin = User.find(session[:role_user_id])
    end
  end
  end

  def get_role_name_by_id(role_id)
    @role_name = Role.where(id: role_id)
  end

  def require_admin_logged_in
    unless admin_log_in?
      flash[:error] = "You need to login first"
      redirect_to admin_login_path
    end
  end

  def validRequest?
    api_key = request.headers["HTTP_ACCESSTOKEN"].presence || session[:partner_user_id]
    serverSession = ServerSession.where(server_token: api_key).first
    @serverSession = serverSession.server_token if serverSession
    @user = serverSession.auth.user
    unless api_key
      redirect_to business_partner_login_path
      # render :json => {:code=>345, :message => "Invalid session token"}
    end
    unless @user.user_detail.blank?
      flash[:error] = "Waiting For HR Approval" if @user.approval_status != User::APPROVAL_STATUS[:approved]
      redirect_to business_partner_login_path if @user.approval_status != User::APPROVAL_STATUS[:approved]
    end
  rescue StandardError
    redirect_to business_partner_login_path
    # render :json => {:code=>345, :message => "Invalid session token!"}
  end

  def to_boolean(value)
    [1, "true", true, "1", "t"].include?(value) ? "true" : "false"
  end

  def used_device
    user_agent = request.headers["HTTP_USER_AGENT"]
    p "==user_agent==#{user_agent}"
    p "====#{user_agent.downcase.include?('iphone')}"
    result = "other"
    if user_agent.present?
      if user_agent.downcase.include?("android")
        result = "android"
      elsif user_agent.downcase.include?("iphone")
        result = "ios"
      elsif user_agent.downcase.include?("window")
        result = "windows"
        p result
      end
    end
    p "========#{result}"
    result
  end

  def restaurant_title(restaurant_id)
    get_restaurant_data(decode_token(restaurant_id))&.title
    rescue Exception => e
  end

  def branch_address(branch_id)
    get_branch_data(decode_token(branch_id))&.address
    rescue Exception => e
  end

  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end

  def get_coverage_area_from_location(latitude, longitude)
    return false if latitude.blank? || longitude.blank?
    area_ids = []
    result = get_here_api_location_details(latitude, longitude)

    if result.present? && result["address"].present?
      city = result["address"]["city"]
      area = CoverageArea.find_by(area: city)
      country_id = Country.find_by(name: result["address"]["countryName"])&.id

      if area
        if ["samaheej", "galali", "galaly"].include?(area.area.to_s.downcase)
          area_ids = point_inside_area?(latitude, longitude)
        else
          area_ids = CoverageArea.active_areas.where(id: area.id).pluck(:id)
        end
      elsif country_id
        new_area = CoverageArea.create(area: city, status: "deactivate", country_id: country_id, requested: true, location: result["address"]["label"], latitude: latitude, longitude: longitude)
      end
    end

    area_ids
  end

  def get_coverage_area_details(latitude, longitude)
    data = {}
    result = get_here_api_location_details(latitude, longitude)

    if result.present? && result["address"].present?
      city = result["address"]["city"]

      if ["samaheej", "galali", "galaly"].include?(city.to_s.downcase)
        area_id = point_inside_area?(latitude.to_f, longitude.to_f).first
      else
        area_id = CoverageArea.active_areas.find_by(area: city)&.id
      end

      country_id = Country.find_by(name: result["address"]["countryName"])&.id
      data = { area_id: area_id, country_id: country_id }
    end

    data
  end

  def get_here_api_location_details(latitude, longitude)
    url = URI("https://revgeocode.search.hereapi.com/v1/revgeocode?at=#{latitude},#{longitude}&lang=en-US&apiKey=#{Rails.application.secrets['here_rest_api_key']}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    result = JSON.parse(response.body)["items"]&.first
    result
  end

  def point_inside_area?(latitude, longitude)
    return false if latitude.blank? || longitude.blank?
    polygonPoints = JSON.parse(File.read("public/AreaBoundries.json")).to_h["coverage_areas"].map { |i| [i["id"], i["coordinates"].map(&:reverse)] }.to_h
    @required_ids = []

    polygonPoints.each do |k, v|
      next if CoverageArea.find_by(id: k).nil?
      x = latitude
      y = longitude
      i = -1
      j = v.size - 1

      while (i += 1) < v.size
        xi = v[i][0]
        yi = v[i][1]
        xj = v[j][0]
        yj = v[j][1]

        if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
          @required_ids << k
        end

        j = i
      end
    end

    @required_ids.uniq
  end

  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60

    seconds = seconds_diff

    "#{hours.to_s} hrs, #{minutes.to_s} mins, #{seconds} sec"
  end

  def time_duration(total_seconds)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    "#{hours.to_i.to_s} hrs, #{minutes.to_i.to_s} mins, #{seconds.to_i.to_s} sec"
  end

  def amount_three_decimal(amount)
    "%.3f" % amount rescue 0
  end

  def check_user_privillage(user)
    privilage_record = ""
    unless user.user_detail.blank?
      designation = Designation.find_by_name(user.user_detail.designation)
      UserPrivilege.all.each do |privilage|
        if privilage.designation_ids.include?(designation.id.to_s)
          privilage_record = privilage 
          break
        end
      end
    end
    privilage_record
  end

  def find_location_familty(employee,name_val=false)
    ids = employee.user_detail.location.split(",") rescue []
    if name_val.present?
       Branch.where(id: ids).pluck(:address).join(",")
    else
      Branch.where(id: ids).pluck(:id)
    end
  end
end
