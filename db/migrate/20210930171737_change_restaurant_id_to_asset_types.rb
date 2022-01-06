class ChangeRestaurantIdToAssetTypes < ActiveRecord::Migration[5.2]
  def change
    change_column :asset_types, :restaurant_id, :string
  end
end
