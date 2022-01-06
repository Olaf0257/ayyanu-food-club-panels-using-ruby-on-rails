class AddAssetGroupIdToAssetTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_types, :asset_group_id, :integer
  end
end
