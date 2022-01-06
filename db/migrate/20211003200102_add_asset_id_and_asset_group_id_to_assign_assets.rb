class AddAssetIdAndAssetGroupIdToAssignAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_assets, :asset_id, :integer
    add_column :assign_assets, :asset_group_id, :integer
  end
end
