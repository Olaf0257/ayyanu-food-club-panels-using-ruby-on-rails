class AddAssetGroupIdToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :asset_group_id, :integer
    add_column :assets, :name, :string
    add_column :assets, :restaurant_id, :string
  end
end
