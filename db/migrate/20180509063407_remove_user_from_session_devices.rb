class RemoveUserFromSessionDevices < ActiveRecord::Migration[5.1]
  def change
    remove_reference :session_devices, :user, foreign_key: true
  end
end
