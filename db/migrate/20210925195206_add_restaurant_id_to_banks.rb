class AddRestaurantIdToBanks < ActiveRecord::Migration[5.2]
  def change
    add_column :banks, :restaurant_id, :integer
  end
end
