class RenameTableAssetTypesToAssetCategories < ActiveRecord::Migration[5.2]
  def change
  	 rename_table :asset_types, :asset_categories
	 rename_table :asset_groups, :asset_types
  	 rename_column :asset_categories, :asset_group_id, :asset_type_id
  	 rename_column :assets, :asset_group_id, :asset_category_id
  end
end
