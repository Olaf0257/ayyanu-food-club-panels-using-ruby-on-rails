class CreateAddAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :add_assets do |t|
      t.string :name
      t.string :restaurant_id
      t.integer :asset_group_id
      t.timestamps
    end
  end
end
