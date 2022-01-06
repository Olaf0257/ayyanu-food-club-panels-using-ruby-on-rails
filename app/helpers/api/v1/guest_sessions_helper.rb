module Api::V1::GuestSessionsHelper
  def add_guest_user_session(device_id, device_type)
    token = guest_ensure_authentication_token(device_id, device_type)
    GuestSession.create_guest_token(device_id, device_type, token)
  end

  def guest_ensure_authentication_token(device_id, device_type)
    server_token = guest_generate_access_token(device_id, device_type)
    # self.auths.last.last_active_at = Time.now
  end

  def guest_generate_access_token(_device_id, device_type)
    loop do
      token = Devise.friendly_token + device_type
      break token unless GuestSession.where(guest_token: token).first
      token = Devise.friendly_token + device_type
    end
  end
end
