class RemoveAssetTypeIdToAssetGroups < ActiveRecord::Migration[5.2]
  def change
  	remove_column :asset_groups, :asset_type_id, :integer
  end
end
