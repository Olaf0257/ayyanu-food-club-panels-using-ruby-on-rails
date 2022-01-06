class Api::V1::RegistrationsController < Api::ApiController
  before_action :validate_role, only: [:create]

  def create
    existingUser = user_email(params[:email])
    userName = user_name(params[:user_name])
    if !userName
      if !existingUser && !userName
        user = add_user(params[:name], params[:email], params[:user_name], params[:password], params[:role], params[:country_code], params[:contact], params[:device_type], params[:device_id], params[:image], params[:country_id])
        if user
          server_session = user[:result].auths.first.server_sessions.first
          update_guest_session_details(user[:result], params[:guest_token])
          update_loggedin_device(server_session, params[:device_type], params[:device_id])
          responce_json(code: 201, user: user[:result].as_json.merge(api_key: server_session.server_token))
        else
          responce_json(code: 422, message: model_errors(user))
        end
      else
        responce_json(code: 422, message: existingUser ? "Username already exists" : "User already exists!")
      end
    else
      responce_json(code: 422, message: "Username already exists")
    end
  rescue StandardError => e
    responce_json(code: 422, message: "Please provide vaild params! #{e}")
  end
end
