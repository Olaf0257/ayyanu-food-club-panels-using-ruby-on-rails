class AddServerSessionRefToSessionDevice < ActiveRecord::Migration[5.1]
  def change
    add_reference :session_devices, :server_session, foreign_key: true
  end
end
