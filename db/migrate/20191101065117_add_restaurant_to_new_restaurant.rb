class AddRestaurantToNewRestaurant < ActiveRecord::Migration[5.1]
  def change
    add_reference :new_restaurants, :restaurant, foreign_key: true,:null => true
  end
end
