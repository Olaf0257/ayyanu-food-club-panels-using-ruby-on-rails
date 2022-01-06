class CreateAssetGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :asset_groups do |t|
      t.string :name
      t.string :restaurant_id
      t.timestamps
    end
  end
end
