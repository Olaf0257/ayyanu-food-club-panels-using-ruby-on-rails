class AddRestaurantIdToStages < ActiveRecord::Migration[5.2]
  def change
    add_column :stages, :restaurant_id, :integer
  end
end
