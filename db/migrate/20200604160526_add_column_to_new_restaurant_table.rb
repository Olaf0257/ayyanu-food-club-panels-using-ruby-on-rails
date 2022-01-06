class AddColumnToNewRestaurantTable < ActiveRecord::Migration[5.1]
  def change
    add_column :new_restaurants, :country_id, :integer
  end
end
