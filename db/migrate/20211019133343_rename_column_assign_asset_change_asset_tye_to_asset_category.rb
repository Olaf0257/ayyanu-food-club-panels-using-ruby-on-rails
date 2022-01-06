class RenameColumnAssignAssetChangeAssetTyeToAssetCategory < ActiveRecord::Migration[5.2]
  def change
  	rename_column :assign_assets, :asset_group_id, :asset_category_id
  end
end
