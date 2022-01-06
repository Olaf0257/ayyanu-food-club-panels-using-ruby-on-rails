class AddAssetTypeIdToAssetGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_groups, :asset_type_id, :integer
  end
end
