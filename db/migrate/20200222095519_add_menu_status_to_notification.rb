class AddMenuStatusToNotification < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :menu_status, :string
  end
end
