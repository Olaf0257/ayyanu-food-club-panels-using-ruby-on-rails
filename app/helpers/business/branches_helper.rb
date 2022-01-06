module Business::BranchesHelper
  require "chronic"

  def redirect_to_root
    session[:partner_user_id] = nil
    flash[:error] = "Unauthorised Access !!"
    redirect_to business_partner_login_path
  end

  def get_branch_data(id)
    Branch.find_by(id: id)
  end

  def branch_add(restaurant, address, contact, max_delivery_time, minimum_order_amount, cash_on_delivery, acept_cash, accept_card, country, area, tax_percentage, delivery_charges, image, latitude, longitude, cr_document, cpr_document)
    url = image.present? ? upload_multipart_image(image, "branch") : ""
    cr_url = cr_document.present? ? upload_multipart_image(cr_document, "branch") : ""
    cpr_url = cpr_document.present? ? upload_multipart_image(cpr_document, "branch") : ""

    Branch.branch(restaurant, address, contact, max_delivery_time, minimum_order_amount, cash_on_delivery, acept_cash, accept_card, country, area, tax_percentage, delivery_charges, url, latitude, longitude, cr_url, cpr_url)
  end

  def update_branch(address, contact, max_delivery_time, minimum_order_amount, cash_on_delivery, acept_cash, accept_card, country, area, tax_percentage, delivery_charges, image, latitude, longitude, cr_document, cpr_document, branch_fee_id, report_fee_id, call_center_number, report, fixed_charge_percentage, max_fixed_charge)
    prev_url = @branch.image.present? ? @branch.image.split("/").last : "n/a"
    url = image.present? ? update_multipart_image(prev_url, image, "branch") : @branch.image
    prev_cr_url = @branch.cr_document.present? ? @branch.cr_document.split("/").last : "n/a"
    cr_url = cr_document.present? ? update_multipart_image(prev_cr_url, cr_document, "branch") : @branch.cr_document
    prev_cpr_url = @branch.cpr_document.present? ? @branch.cpr_document.split("/").last : "n/a"
    cpr_url = cpr_document.present? ? update_multipart_image(prev_cpr_url, cpr_document, "branch") : @branch.cpr_document

    @branch.update(address: address, delivery_time: max_delivery_time, min_order_amount: minimum_order_amount, cash_on_delivery: cash_on_delivery, accept_cash: acept_cash, accept_card: accept_card, country: country, tax_percentage: tax_percentage.presence || 5.0, delivery_charges: delivery_charges, contact: contact, image: url, latitude: latitude, longitude: longitude, cr_document: cr_url, cpr_document: cpr_url, city: CoverageArea.find(area).area, call_center_number: call_center_number, report: report, fixed_charge_percentage: fixed_charge_percentage, max_fixed_charge: max_fixed_charge)
    @branch.update(branch_subscription_id: branch_fee_id) if branch_fee_id.present?
    @branch.update(report_subscription_id: report_fee_id) if report_fee_id.present?
    @branch.branch_timings.destroy_all

    params.select { |k, _v| k.include?("opening_time") }.each do |k, v|
      day = k.split("_")[2]
      count = k.split("_")[3]

      if params["open_#{day}"] == "1"
        BranchTiming.create(opening_time: params["opening_time_#{day}_#{count}"], closing_time: params["closing_time_#{day}_#{count}"], day: day, branch_id: @branch.id)
      end
    end
  end

  def get_subscribe_report(restaurant, status)
    case status
    when "subscribe"
      restaurant_report = current_month_restaurant_report(restaurant)
      if restaurant_report.present?
        { code: 200, message: "Already subscribed reports for this month!!" }
      else
        Subscription.add_subscribe_report(restaurant, nil)
        { code: 200, message: "Successfully subscribe reports." }
      end
    when "un_subscribe"
      restaurant_report = current_month_restaurant_report(restaurant)
      restaurant_report.last.update(unsubscribe_date: Date.today, is_subscribe: false) # , report_expaired_at: Date.today.end_of_month)
      { code: 200, message: "Successfully unsubscribe reports." }
    end
  end

  def upload_doc_on_dropbox
    app_key = "gf3h7ccuo7pvhm3"
    app_secret = "ab35tygk5uz1xnx"
    dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ")
    file = open(params[:upload_contract_document][:file])
    file_name = params[:upload_contract_document][:file].original_filename
    file = dbx.upload("/#{Time.now.to_i}#{file_name}", file)
    result = HTTParty.post("https://api.dropboxapi.com/2/sharing/create_shared_link",
                           body: { path: file.path_display }.to_json,
                           headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAGn94L0ztu96ZTjBmlc9sHl9kvzfqG98YaHBWCjLUOBvQ", "Content-Type" => "application/json" })
    url = result.parsed_response["url"]
    rescue Exception => e
  end

  def delete_perivious_file_on_dropbox(file)
    app_key = "gf3h7ccuo7pvhm3"
    app_secret = "ab35tygk5uz1xnx"
    dbx = Dropbox::Client.new("4wymnERGF4AAAAAAAAAAS2h_JFUx1uMAgeM401mKaY0qp6R8GvZxSrAbmQSgVvdK")
    result = HTTParty.post("https://api.dropboxapi.com/2/files/delete_v2",
                           data: { path: file.doc_url }.to_json,
                           headers: { "Authorization" => "Bearer 4wymnERGF4AAAAAAAAAAS2h_JFUx1uMAgeM401mKaY0qp6R8GvZxSrAbmQSgVvdK", "Content-Type" => "application/json" })
                          rescue Exception => e
  end

  def get_branch_caverage_area(branch_coverage_area_id)
    BranchCoverageArea.find_by(id: branch_coverage_area_id)
  end

  def branch_caverage_area(area, branch)
    BranchCoverageArea.find_by(coverage_area_id: area, branch_id: branch)
  end

  def get_branch_categories(branch, category_id)
    branch.branch_categories.where(category_id: category_id)
  end

  def get_branch_categories_data(category_id)
    BranchCategory.find_by(id: category_id)
  end

  def get_restaurant_deatils(restaurant_id)
    Restaurant.find_by(id: restaurant_id)
  end

  def update_restaurant(restaurant, res_logo, restaurant_name, restaurant_name_ar, _owner_name)
    prev_img = restaurant.logo.present? ? restaurant.logo.split("/").last : "n/a"
    logo = res_logo.present? ? update_multipart_image(prev_img, res_logo, "logos") : restaurant.logo
    restaurant.update(logo: logo, title: restaurant_name, title_ar: restaurant_name_ar)
  end

  def send_email_branch_busy_and_close(email, area)
    RestaurantMailer.send_email_on_restaurant_owner_with_area_status(email, area).deliver_now
    rescue Exception => e
  end

  def current_month_restaurant_report(restaurant)
    restaurant.subscriptions.where("(DATE(subscribe_date) <= ? and is_subscribe = ?) or (MONTH(subscribe_date) = ? and is_subscribe = ?)", Date.today, true, Date.today.month, false)
  end

  def is_new_menu_item(item_name, price_per_item, item_image, cropped_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu, include_in_pos, include_in_app, preparation_time = 15)
    image = item_image.present? ? upload_multipart_image(item_image, "menu_item") : nil unless cropped_image.present?
    if image.present?
      MenuItem.newMenuItem(item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu, include_in_pos, include_in_app, preparation_time)
    else
      MenuItem.newMenuItem(item_name, price_per_item, cropped_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu, include_in_pos, include_in_app, preparation_time)
    end
  end

  def is_update_menu_item(item, item_name, price_per_item, new_item_image, cropped_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, item_date, addon_category_id, far_menu, include_in_pos=nil, include_in_app=nil, menu_item_ids, recipe_ids, station_ids)
    prev_img = item.item_image.present? ? item.item_image.split("/").last.split(".")[0] : "n/a"
    if cropped_image.present?
      image = (new_item_image.present? && prev_img.present?) ? remove_multipart_image(prev_img, "menu_item") : item.item_image.presence
      menu = MenuItem.updateMenuItem(item, item_name, price_per_item, cropped_image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, far_menu, menu_item_ids, recipe_ids, station_ids)
    else
      image = new_item_image.present? ? update_multipart_image(prev_img, new_item_image, "menu_item") : item.item_image.presence
      menu = MenuItem.updateMenuItem(item, item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, far_menu, menu_item_ids, recipe_ids, station_ids)
    end
    add_daily_dishes_date(item_date, item) if item_date.present?
    create_add_on(addon_category_id, item)
  end
end
