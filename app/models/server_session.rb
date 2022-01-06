class ServerSession < ApplicationRecord
  belongs_to :auth
  has_one :session_device, dependent: :destroy
end
