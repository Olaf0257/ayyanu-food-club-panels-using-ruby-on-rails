class Api::V1::SessionsController < Api::ApiController
  before_action :validate_user, only: [:create]
  before_action :validate_transpoter, only: [:transporter_login]
  before_action :authenticate_api_access, only: [:logout, :user_details]
  before_action :validate_role, :userExistsWithProviderDetails, only: [:social_auth]

  def create
    # @auth.server_sessions.destroy_all if @auth.present?
    guest_token = params[:session].present? ? params[:session][:guest_token] : params[:guest_token]
    device_type = params[:session].present? ? params[:session][:device_type] : params[:device_type]
    device_id = params[:session].present? ? params[:session][:device_id] : params[:device_id]

    sign_in @auth, store: false
    update_guest_session_details(@user, guest_token)
    server_session = @auth.server_sessions.create(server_token: @auth.ensure_authentication_token)
    update_loggedin_device(server_session, device_type, device_id)
    @user.auths.first.role == "business" ? responce_json(code: 200, user: business_user_login_json(@user).merge(api_key: server_session.server_token, role: @auth.role)) : @user.auths.first.role == "manager" ? responce_json(code: 200, user: manager_user_login_json(@user).merge(api_key: server_session.server_token, role: @auth.role)) : responce_json(code: 200, user: user_login_json(@user).merge(api_key: server_session.server_token, role: @auth.role))
  end

  def social_auth
    socialAuthentication
    sign_in @existingAuth, store: false
    update_guest_session_details(@user, params[:guest_token])
    server_session = @existingAuth.server_sessions.create(server_token: @existingAuth.ensure_authentication_token)
    update_loggedin_device(server_session, params[:device_type], params[:device_id])
    responce_json(code: 201, user: user_login_json(@user).merge(api_key: server_session.server_token))
  rescue StandardError => e
    responce_json(code: 422, message: "Invalid request! #{e}")
  end

  def user_details
    responce_json(code: 200, message: "User details successfully!", user: user_login_json(@user).merge(api_key: request.headers["HTTP_ACCESSTOKEN"]))
  end

  def check_email_or_username
    email = user_email(params[:email])
    userName = user_name(params[:user_name])
    if email.present?
      responce_json(code: 422, message: "User email already exists!", status: true)
    elsif userName.present?
      responce_json(code: 422, message: "User name already exists!", status: true)
    else
      responce_json(code: 404, message: "User not found!", status: false)
    end
  end

  def logout
    session = get_server_session(request.headers["accessToken"])
    if session
      case params[:logout_by]
      when "all"
        session.auth.server_sessions.destroy_all
      else
        session.destroy
      end
      responce_json(code: 200, message: "User logout successfully!")
    else
      responce_json(code: 422, message: "Invalid request!")
    end
  end

  def forgot_password
    user = user_email(params[:email])
    if user.present?
      update_forget_token(user, user.auths.first.role)
      responce_json(code: 200, message: "Otp sent successfully!", email: params[:email])
    else
      responce_json(code: 404, message: "User does not exist!")
    end
  rescue StandardError
    responce_json(code: 422, message: "Invalid request!")
  end

  def otp_verification
    user = user_email(params[:email])
    if user
      user_auth = get_user_auth(user, user.auths.first.role)
      is_verified = is_verified_otp(user_auth, params[:otp].presence || "blank")
      if is_verified
        responce_json(code: 200, message: "Otp verified", is_verified: is_verified, reset_password_token: user_auth.reset_password_token)
      else
        responce_json(code: 422, message: "Please recheck your input as it does not match our records.")
      end
    else
      responce_json(code: 404, message: "User does not exists")
    end
  end

  def reset_password_through_token
    if request.headers["HTTP_PASSWORDTOKEN"].present?
      user_auth = get_user_auth_through_passwordToken(request.headers["HTTP_PASSWORDTOKEN"])
      p "----------------"
      p user_auth
      if user_auth && params[:password].present?
        begin
          sentTime = (Time.now - user_auth.reset_password_sent_at) / 60
          if sentTime <= 10
            user_auth.update!(password: params[:password], reset_password_sent_at: nil, reset_password_token: nil)
            responce_json(code: 200, message: "Password has been reset successfully!")
          else
            user_auth.update!(reset_password_sent_at: nil, reset_password_token: nil)
            responce_json(code: 423, errors: "Password Token has been expired!")
          end
        rescue StandardError => e
          responce_json(code: 423, errors: e.to_s)
        end
      else
        responce_json(code: 424, errors: user_auth ? "Password can't be blank!" : "Invalid Password recovery Token!")
      end
    else
      responce_json(code: 404, errors: "You forgot to add Password recovery token")
    end
  end

  def password_recovery
    # token.split("u")[0].split("t")[1]
    user = is_verified_password_token(params[:token])
    recover_password(user, params[:new_password]) ? send_json_response("You have successfully updated your password. You can now login with the new password.", "success", is_updated: true) : responce_json(code: 423, message: "User invalid")
  end

  def web_password_recovery
    user = web_is_verified_password_token(params[:token])
    web_recover_password(user, params[:new_password]) ? send_json_response("You have successfully updated your password. You can now login with the new password.", "success", is_updated: true) : responce_json(code: 423, message: "User invalid")
  end

  def transporter_login
    sign_in @auth, store: false
    server_session = @auth.server_sessions.create(server_token: @auth.ensure_authentication_token)
    update_loggedin_device(server_session, params[:session][:device_type], params[:session][:device_id])
    responce_json(code: 200, user: user_login_json(@user).merge(api_key: server_session.server_token, role: @auth.role))
  end

  private

  def validate_user
    if params[:session].present?
      email = params[:session][:email]
      password = params[:session][:password]
      role = params[:session][:role]
    else
      email = params[:email]
      password = params[:password]
      role = params[:role]
    end
    @userData = user_email_or_userName(email)
    @user = @userData ? @userData : user_restaurant_login(email)
    @auth = @user.auths.find_by(role: params[:role].presence || @user.auths.first.role)

    unless @user && @auth.valid_password?(password) && (@user.auths.first.role == role)
      responce_json(code: 422, message: (@user.auths.first.role == "business" ? "The email and password entered do not match our records. Please contact to Food Club if needed." : "The email and password entered do not match our records. Please reenter the information or reset your password if needed.").to_s)
    end
  rescue StandardError
    responce_json(code: 422, message: "The Email Address or Password does not match our records.")
  end

  def userExistsWithProviderDetails
    user = user_email(params[:email])
    userName = params[:email].split("@").first if params[:email]
    @user = user ? user : add_user(params[:name], params[:email], userName, "#{params[:provider_id]}@#{params[:provider_type]}", params[:role], params[:country_code], params[:contact], params[:device_type], params[:device_id], params[:image], params[:country_id])[:result]
    unless @user && params[:Provider_id].present? && params[:provider_type].present?
      responce_json(code: 422, message: (@user ? "Social detail does not exists" : "User does not exists!").to_s)
    end
  end

  def socialAuthentication
    @existingSocialAuth = @user.social_auths.where(provider_id: params[:provider_id], provider_type: params[:provider_type]).first
    @existingSocialAuth ||= @user.social_auths.create(provider_id: params[:provider_id], provider_type: params[:provider_type])
    @existingAuth = @user.auths.find_by(role: params[:role])
    @existingAuth ||= @user.auths.create(role: params[:role], password: "#{@user.id}.#{params[:provider_id]}@#{params[:provider_type]}")
  end

  def validate_transpoter
    cprNumber = params[:session].present? ? params[:session][:cpr_number] : params[:cpr_number]
    password = params[:session].present? ? params[:session][:password] : params[:password]
    role = params[:session].present? ? params[:session][:role] : params[:role]
    @user = User.find_by(cpr_number: cprNumber, is_approved: [0, 1])
    @auth = @user.auths.find_by(role: @user.auths.first.role)

    unless @user && @auth.valid_password?(password) && (@user.auths.first.role == role)
      responce_json(code: 422, message: "The cpr number and password entered do not match our records. Please contact your manager.")
    end

  rescue StandardError
    responce_json(code: 422, message: "The cpr number and password entered do not match our records. Please contact your manager.")
  end
end
