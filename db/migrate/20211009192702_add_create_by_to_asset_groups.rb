class AddCreateByToAssetGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_groups, :created_by_id, :integer
  end
end
