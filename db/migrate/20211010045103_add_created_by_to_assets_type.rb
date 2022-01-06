class AddCreatedByToAssetsType < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_types, :created_by_id, :integer
  end
end
