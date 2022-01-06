class AddIndexToSessionDevices < ActiveRecord::Migration[5.1]
  def change
  	add_index :session_devices, :device_id
  	add_index :session_devices, :device_type
  	
  end
end
