class AddRestaurantIdToSalaries < ActiveRecord::Migration[5.2]
  def change
    add_column :salaries, :restaurant_id, :integer
    add_column :family_details, :restaurant_id, :integer
  end
end
