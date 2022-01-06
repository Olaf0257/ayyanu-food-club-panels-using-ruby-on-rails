class AddIndexToGuestSessions < ActiveRecord::Migration[5.1]
  def change
  	add_index :guest_sessions, :device_id
  	add_index :guest_sessions, :device_type
  end
end
