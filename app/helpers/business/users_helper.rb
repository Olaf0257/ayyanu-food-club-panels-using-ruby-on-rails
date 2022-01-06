module Business::UsersHelper
  def create_employee(branch, username, email, role, contact, country_code, password, image, cpr_number, vehicle_type=nil,dob=nil,cpr_number_expiry=nil, gender=nil, status=nil, user=nil)
    url = image.present? ? upload_multipart_image(image, "user") : nil
    user = User.create_user(username, role, email, "", country_code, contact, url, cpr_number, nil, vehicle_type,dob,cpr_number_expiry, gender)
    auth = (user[:code] == 200 ? user[:result].auths.create(password: password, role: role) : false)
    if auth && role == "transporter"
      branch = BranchTransport.create_branch_transporters(user[:result], branch)
    elsif auth && role == "manager"
      branch = branch.split(",") if branch.class == String
      branch.reject(&:empty?).each do |branch_id|
        b = Branch.find(branch_id)
        manager = BranchManager.create_branch_managers(user[:result], b)
      end
    elsif auth
      manager = BranchKitchenManager.create_branch_kitchen_managers(user[:result], branch)
    end

    user[:result].save if user[:code] == 200
    user[:result]
  end

  def create_delivery_transporter(username, email, role, contact, country_code, password, image, cpr_number, company_id, zone_ids, vehicle_type)
    url = image.present? ? upload_multipart_image(image, "user") : nil
    user = User.create_user(username, role, email, "", country_code, contact, url, cpr_number, nil, vehicle_type)

    if user[:code] == 200
      auth = user[:result].auths.create(password: password, role: role)

      zone_ids&.each do |zone_id|
        user[:result].zones << Zone.find(zone_id)
      end

      user[:result].update(delivery_company_id: company_id)
    else
      auth = false
    end

    user[:result]
  end

  def find_branch_transporter(branch)
    transporters = branch.users.where(status: true)
  end

  def find_branch_managers(branch)
    managers = branch.managers.all
  end

  def branch_kitchen_managers(branch)
    managers = branch.kitchen_managers.all
  end

  def update_employee(user, firstname, _role, contact, country_code, image, vehicle_type)
    prev_img = user.image.present? ? user.image.split("/").last.split(".")[0] : "blank"
    url = image.present? ? update_multipart_image(prev_img, image, "user") : nil
    img_url = url.presence || user.image
    res = user.update!(name: firstname, contact: contact.delete(" "), country_code: country_code, image: img_url, vehicle_type: vehicle_type)
    user
  end

  def update_employee_with_details(branch, username, email, role, contact, country_code, password, image, cpr_number, vehicle_type, dob, cpr_number_expiry, gender, status, user)
    url = image.present? ? upload_multipart_image(image, "user") : nil
    user = user.update_user(username, role, email, "", country_code, contact, url, cpr_number, nil, vehicle_type,dob, cpr_number_expiry, gender, status)

    unless password.blank?
      user[:result].auths.map{|a| a.destroy} rescue nil
      auth = (user[:code] == 200 ? user[:result].auths.create(password: password, role: role) : false)
    end

    if user[:result].auths && role == "transporter"
      branch = BranchTransport.create_branch_transporters(user[:result], branch)
    elsif user[:result].auths && role == "manager"
      unless branch.class == String
        user[:result].branch_managers.delete_all
        branch.reject(&:empty?).each do |branch_id|
          b = Branch.find(branch_id)
          manager = BranchManager.create_branch_managers(user[:result], b)
        end
      end
    elsif user[:result].auths
      manager = BranchKitchenManager.create_branch_kitchen_managers(user[:result], branch)
    end

    user[:result].save if user[:code] == 200
    user[:result]
  end

  def update_delivery_transporter(user, firstname, contact, country_code, image, zone_ids, vehicle_type)
    prev_img = user.image.present? ? user.image.split("/").last.split(".")[0] : "blank"
    url = image.present? ? update_multipart_image(prev_img, image, "user") : nil
    img_url = url.presence || user.image

    if user.update!(name: firstname, contact: contact.delete(" "), country_code: country_code, image: img_url, vehicle_type: vehicle_type)
      user.zones.destroy_all

      zone_ids&.each do |zone_id|
        user.zones << Zone.find(zone_id)
      end
    end

    user
  end

  def get_transporters(restaurant)
    restaurant = restaurant.presence || @user.manager_branches.first.restaurant
    User.joins(branch_transports: :branch).where("restaurant_id = ?", restaurant.id).distinct.paginate(page: params[:page], per_page: params[:per_page])
  end

  def get_managers(restaurant)
    restaurant = restaurant.presence || @user.manager_branches.first.restaurant
    User.joins(branch_managers: :branch).where("restaurant_id = ?", restaurant.id).distinct.paginate(page: params[:page], per_page: params[:per_page])
  end

  def get_kitchen_managers(restaurant)
    restaurant = restaurant.presence || @user.manager_branches.first.restaurant
    User.joins(branch_kitchen_managers: :branch).where("restaurant_id = ?", restaurant.id).distinct.paginate(page: params[:page], per_page: params[:per_page])
  end

  def filter_data(restaurant, branch, keyword, vehicle_type)
    if branch.present? && keyword.present?
      result = find_branch_transporter(branch).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present?
      result = find_branch_transporter(branch).paginate(page: params[:page], per_page: params[:per_page])
    elsif keyword.present?
      result = get_transporters(restaurant).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    else
      result = get_transporters(restaurant)
    end

    if vehicle_type.present?
      vehicle_type = vehicle_type == "true" ? true : false
      result = result.where(vehicle_type: vehicle_type)
    else
      result
    end
  end

  def filter_data_without_paginate(restaurant, branch, keyword, vehicle_type)
    if branch.present? && keyword.present?
      result = find_branch_transporter(branch).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%")
    elsif branch.present?
      result = find_branch_transporter(branch)
    elsif keyword.present?
      result = get_transporters(restaurant).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%")
    else
      result = get_transporters(restaurant)
    end

    if vehicle_type.present?
      vehicle_type = vehicle_type == "true" ? true : false
      result = result.where(vehicle_type: vehicle_type)
    else
      result
    end
  end

  def filter_delivery_company_transport(keyword, cpr_number, vehicle_type)
    @transporters = @user.delivery_company.users.joins(:auths).where(auths: { role: "transporter" }).reject_ghost_driver
    @transporters = @transporters.where("name LIKE ? or email = ?", "%#{keyword}%", keyword) if keyword.present?
    @transporters = @transporters.where(cpr_number: cpr_number) if cpr_number.present?

    if vehicle_type.present?
      vehicle_type = vehicle_type == "true" ? true : false
      @transporters = @transporters.where(vehicle_type: vehicle_type)
    else
      @transporters
    end

    @transporters.paginate(page: params[:page], per_page: 20)
  end

  def search_by_name_and_email(keyword)
    User.where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%")
  end

  def filter_managers(restaurant, branch, keyword)
    if branch.present? && keyword.present?
      result = find_branch_managers(branch).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present?
      result = find_branch_managers(branch).paginate(page: params[:page], per_page: params[:per_page])
    elsif keyword.present?
      result = get_managers(restaurant).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    else
      result = get_managers(restaurant)
    end
    result
  end

  def filter_kitchen_managers(restaurant, branch, keyword)
    if branch.present? && keyword.present?
      result = branch_kitchen_managers(branch).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present?
      result = branch_kitchen_managers(branch).paginate(page: params[:page], per_page: params[:per_page])
    elsif keyword.present?
      result = get_kitchen_managers(restaurant).where("name LIKE ? or email LIKE ?", "%#{keyword}%", "%#{keyword}%").paginate(page: params[:page], per_page: params[:per_page])
    else
      result = get_kitchen_managers(restaurant)
    end
    result
  end

  def get_email_details(email)
    User.find_by(email: email)
  end

  def get_user_with_role(email)
    User.joins(:auths).where("role IN (?) and email = ?", %w[business manager kitchen_manager delivery_company], email).first
  end
end
