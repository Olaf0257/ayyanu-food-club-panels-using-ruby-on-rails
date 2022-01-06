class CreateMajorGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :major_groups do |t|
      t.string :name
      t.references :restaurant, foreign_key: true
      t.references :over_group, foreign_key: true

      t.timestamps
    end
  end
end
