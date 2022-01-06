module Api::V1::UsersHelper
  def user_email(email)
    User.find_by(email: email)
  end

  def user_deatils_with_role(email, role)
    User.joins(:auths).where("email = ? and role = ? ", email, role).first
  end

  def user_login_json(user)
    user.as_json
  end

  def user_email_or_userName(email)
    userData = User.find_by(email: email)
    if userData
      userData
    else
      User.find_by(user_name: email)
    end
  end

  def user_name(user_name)
    User.find_by(user_name: user_name)
  end

  def get_user_cpr_number(cprNumber)
    User.find_by(cpr_number: cprNumber)
  end

  def find_user(user_id)
    User.get_user(user_id)
  end

  def user_except_attributes
    { except: [:created_at, :updated_at, :image] }
  end

  def transporters_json(transporters, order_id)
    transporters.as_json(order: order_id, methods: [:amount])
  end

  def iou_json(iou)
    iou.as_json
  end

  def business_user_login_json(user)
    user.as_json(include: { restaurants: { only: [:id, :title], include: { branches: { only: [:id, :address, :city, :zipcode, :state, :country] } } } })
  end

  def manager_user_login_json(user)
    user.as_json.merge(restaurant: { title: user.branch_managers.first.branch.restaurant.title, branches: [{ id: user.branch_managers.first.branch.id, address: user.branch_managers.first.branch.address, city: user.branch_managers.first.branch.city, zipcode: user.branch_managers.first.branch.zipcode, state: user.branch_managers.first.branch.state, country: user.branch_managers.first.branch.country }] })
  end

  def update_loggedin_device(server_session, device_type, device_id)
    if server_session && device_type.present? && device_id.present?
      lastDevice = server_session.session_device
      if lastDevice
        lastDevice.update(device_type: device_type.downcase, device_id: device_id, session_token: server_session.server_token)
      else
        lastDevice = server_session.create_session_device(device_type: device_type.downcase, device_id: device_id, session_token: server_session.server_token)
      end
    end
  rescue StandardError
  end

  def add_user(name, email, user_name, password, role, country_code, contact, _device_type, _device_id, image, country_id)
    url = image.present? ? upload_multipart_image(image, "user") : nil
    user = User.create_user(name, role, email, user_name, country_code, contact, url, "", country_id, nil)

    if user[:code] == 200
      auth = Auth.create_user_password(user[:result], password, role)
      referral = Referral.find_by(email: user[:result].email)
      referral_coupon = ReferralCoupon.where("DATE(start_date) <= ? AND DATE(end_date) >= ?", Time.zone.today, Time.zone.today).first

      if referral && referral_coupon && role == "customer"
        ReferralCouponUser.create(referral_coupon_id: referral_coupon.id, user_id: user[:result].id, referrer: false)
        ReferralCouponWorker.perform_async(referral_coupon.id, user[:result].id, false)
        ReferralCouponUser.create(referral_coupon_id: referral_coupon.id, user_id: referral.user_id, referrer: true)
        ReferralCouponWorker.perform_async(referral_coupon.id, referral.user_id, true)
      end

      auth.server_sessions.create(server_token: auth.ensure_authentication_token)
    end

    user
  end

  def manage_user_auths(user, password, role)
    existingRole = user.auths.where(role: role).first
    if existingRole.blank?
      auth = user.auths.create(password: password, role: role)
      server_session = auth.server_sessions.create(server_token: auth.ensure_authentication_token)
      update_loggedin_device(server_session, params[:device_type], params[:device_id])
      responce_json(code: 201, user: user.as_json.merge(api_key: server_session.server_token))
    else
      responce_json(code: 422, message: "User already exists!")
    end
  end

  def new_user(email, name, role, contact, country_code)
    password = ((0..9).to_a + ("A".."Z").to_a).sample(8).join
    user = User.create_user(name, email, country_code, contact)
    if user[:code] == 200
      Auth.create_user_password(user[:result], password, role)
    end
    user
   end

  def new_social_auth(provider_id, provider_type, user)
    SocialAuth.create_social_auth(provider_id, provider_type, user)
  end

  def get_server_session(server_token)
    session = ServerSession.find_by(server_token: server_token)
  end

  def update_forget_token(user, role)
    auth = User.update_token(user, role)
    send_forget_password_email(user, auth)
  end

  def send_forget_password_email(user, auth)
    UserMailer.forget_password(user, auth).deliver_now
  rescue StandardError
  end

  def get_user_auth(user, role)
    auth = user.auths.find_by(role: role)
  end

  def is_verified_password_token(token)
    orignal_token = decode_token(token)
    user_id = orignal_token ? orignal_token.split("otp")[0] : 0
    Auth.with_password_token(user_id, token)
  end

  # token.split("u")[0].split("t")[1]
  def web_is_verified_password_token(token)
    # orignal_token = decode_token(token)
    user_id = token.split("u")[0].split("t")[1]
    Auth.with_password_token(user_id, token)
  end

  def web_recover_password(user, new_password)
    user && new_password.present? ? Auth.update_password(user, new_password) : false
  end

  def recover_password(user, new_password)
    user && new_password.present? ? Auth.update_password(user.auths.first, new_password) : false
  end

  def get_user_auth_through_passwordToken(password_token)
    Auth.find_by(reset_password_token: password_token)
  end

  def is_verified_otp(auth, otp)
    auth.otp == otp
  rescue StandardError
    false
  end

  def update_user_device_token(device_token, device_type, access_token, user)
    User.edit_device_token(device_token, device_type, access_token, user)
  end

  def is_user_updated(user, name, country_code, contact, image)
    if user
      prev_img = user.image.present? ? user.image.split("/").last.split(".")[0] : "blank"
      url = image.present? ? update_multipart_image(prev_img, image, "user") : nil
      img_url = url.presence || user.image
      is_updated = User.update_user_profile(user, name, country_code, contact.delete(" "), img_url)
    else
      { code: 400, result: "Profile not updated" }
    end
  end

  def user_address_add(user, guestToken, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude, area_id)
    if user
      Address.create_address(user, nil, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude, area_id)
    else
      p "=====#{guestToken}============="
      user = add_guest_user(guestToken, fname, lname)
      p user.to_s
      Address.create_address(user, guestToken, address_type, address_name, fname, lname, area, block, street, building, floor, apartment_number, additional_direction, country_code, contact, landline, latitude, longitude, area_id) if user.present?
    end
  end

  def update_user_status(user)
    user = find_user(user.id)
    user.present? ? user.update(status: user.status != true) : false
  end

  # def get_user_with_role user,role
  #   user.auths.find_by_role(role)
  # end

  def add_guest_user(guestToken, fname, lname)
    email = guestToken + "@foodclube.com"
    fname = fname.presence || ""
    lname = lname.presence || ""
    name = fname + lname
    user_name = fname + guestToken
    user = User.new(email: email, user_name: user_name, name: name)

    if user.save
      Auth.create_user_password(user, fname + "123456", "customer")
    end

    user
  end
end
