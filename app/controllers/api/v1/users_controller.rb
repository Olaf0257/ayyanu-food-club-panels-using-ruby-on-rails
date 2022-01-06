class Api::V1::UsersController < Api::ApiController
  before_action :authenticate_api_access
  before_action :validate_user, only: [:reset_password]

  def edit_profile
    # server_token = get_server_session(request.headers['accessToken'])
    is_updated = is_user_updated(@user, params[:name], params[:country_code], params[:contact], params[:image])
    is_updated[:code] == 200 ? @user.auths.first.role == "business" ? responce_json(code: 200, message: "Profile updated successfully", user: business_user_login_json(@user).merge(api_key: request.headers["accessToken"], role: @user.auths.first.role)) : responce_json(code: 200, message: "Profile updated successfully", user: user_login_json(@user).merge(api_key: request.headers["accessToken"])) :	send_json_response((is_updated[:result]).to_s, "invalid", {})
  end

  # pending api
  def user_online_offline
    status = update_user_status(@user)
    status ? responce_json(code: 200, message: "User updated successfully") : responce_json(code: 422, message: "Invalid User")
  end

  def update_language
    user = @user.update(language: params[:language])
    responce_json(code: 200, message: "Default language updated successfully")
  end

  def reset_password
    auth = get_user_auth(@user, @user.auths.first.role)
    begin
      if auth.valid_password?(params[:old_password])
        auth.update(password: params[:new_password])
        @user.auths.first.role == "business" ? responce_json(code: 200, message: "Password change successfully", user: business_user_login_json(@user).merge(api_key: request.headers["accessToken"])) : responce_json(code: 200, message: "Password change successfully", user: user_login_json(@user).merge(api_key: request.headers["accessToken"]))
      else
        responce_json(code: 404, message: "Old password doesn't match")
      end
    rescue Exception => e
      responce_json(code: 422, message: model_errors(user))
    end
   end

  def device_token_update
    device = update_user_device_token(params[:device_token], params[:device_type], request.headers["accessToken"], @user)
    responce_json(code: 200, message: "Device token updated successfully")
  end

  def nofitication_clear
    notifications = @user.received_notifications.destroy_all
    responce_json(code: 200, message: "Nofitication clear successfully")
  end

  private

  def validate_user
    useRole = get_user_auth(@user, @user.auths.first.role)
    unless useRole && params[:old_password].present? && params[:new_password].present?
      responce_json(code: 422, message: (useRole ? "Required parameter messing!!" : "User does not exist!!").to_s)
       end
    end
end
