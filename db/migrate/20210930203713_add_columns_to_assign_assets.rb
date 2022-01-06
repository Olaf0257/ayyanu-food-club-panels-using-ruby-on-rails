class AddColumnsToAssignAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assign_assets, :user_id, :integer
    add_column :assign_assets, :asset_type_id, :integer
    add_column :assign_assets, :asset_status, :string
    change_column :assign_assets, :restaurant_id, :string
  end
end
