class AddIndexToNotifications < ActiveRecord::Migration[5.1]
  def change
  	add_index :notifications, :receiver_id
  end
end
