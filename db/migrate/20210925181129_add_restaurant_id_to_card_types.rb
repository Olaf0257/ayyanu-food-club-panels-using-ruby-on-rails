class AddRestaurantIdToCardTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :card_types, :restaurant_id, :integer
  end
end
