class AddRestaurantToStores < ActiveRecord::Migration[5.2]
  def change
    add_reference :stores, :restaurant, foreign_key: true
  end
end
