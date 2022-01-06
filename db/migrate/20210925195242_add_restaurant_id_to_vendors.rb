class AddRestaurantIdToVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :vendors, :restaurant_id, :integer
  end
end
