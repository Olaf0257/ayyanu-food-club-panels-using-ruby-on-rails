class CreateProductionGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :production_groups do |t|
      t.string :name
      t.string :operation_type
      t.references :user, foreign_key: true
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
