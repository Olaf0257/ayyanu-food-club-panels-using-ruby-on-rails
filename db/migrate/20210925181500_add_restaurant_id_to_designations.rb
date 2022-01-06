class AddRestaurantIdToDesignations < ActiveRecord::Migration[5.2]
  def change
    add_column :designations, :restaurant_id, :integer
  end
end
