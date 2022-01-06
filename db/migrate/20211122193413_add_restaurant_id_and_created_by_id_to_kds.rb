class AddRestaurantIdAndCreatedByIdToKds < ActiveRecord::Migration[5.2]
  def change
    add_column :kds, :restaurant_id, :string
    add_column :kds, :created_by_id, :string
  end
end
