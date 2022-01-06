class AddRestaurantidColumnToLoantypes < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_types, :restaurant_id, :integer
  end
end
