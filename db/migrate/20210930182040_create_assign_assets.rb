class CreateAssignAssets < ActiveRecord::Migration[5.2]
  def change
    create_table :assign_assets do |t|
      t.date :valid_till
      t.date :returned_on
      t.string :remarks
      t.integer :restaurant_id
      t.timestamps
    end
  end
end
