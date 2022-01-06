class CreateItemGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :item_groups do |t|
      t.string :name
      t.references :restaurant, foreign_key: true
      t.references :major_group, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
