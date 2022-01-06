class Api::V1::GuestSessionsController < Api::ApiController
  def guest_token
    guestToken = add_guest_user_session(params[:device_id], params[:device_type])
    responce_json(code: 200, message: "Guest token successfully created.", guest_token: guestToken.guest_token)
  end
end
