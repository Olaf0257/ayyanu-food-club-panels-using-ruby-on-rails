class AddRestaurantIdToNotification < ActiveRecord::Migration[5.1]
  def change
    add_reference :notifications, :restaurant, foreign_key: true
  end
end
