class GuestSession < ApplicationRecord
  def as_json(options = {})
    super(options.merge(except: [:device_id, :device_type, :created_at, :updated_at]))
    end

  def self.create_guest_token(device_id, device_type, token)
    token = new(device_id: device_id, device_type: device_type, guest_token: token)
    token.save!
    token
  end
end
