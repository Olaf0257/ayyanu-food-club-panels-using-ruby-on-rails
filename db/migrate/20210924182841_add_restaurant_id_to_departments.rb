class AddRestaurantIdToDepartments < ActiveRecord::Migration[5.2]
  def change
    add_column :departments, :restaurant_id, :integer
  end
end
