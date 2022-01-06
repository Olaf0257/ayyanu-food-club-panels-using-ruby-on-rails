class CreateRecipes < ActiveRecord::Migration[5.2]
  def change
    create_table :recipes do |t|
      t.string :name
      t.float :yields
      t.float :total_weight
      t.references :restaurant, foreign_key: true
      t.references :country, foreign_key: true
      t.references :branch, foreign_key: true
      t.references :over_group, foreign_key: true
      t.references :major_group, foreign_key: true
      t.references :recipe_group, foreign_key: true
      t.references :unit, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
