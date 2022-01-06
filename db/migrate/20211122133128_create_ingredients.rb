class CreateIngredients < ActiveRecord::Migration[5.2]
  def change
    create_table :ingredients do |t|
      t.float :quantity
      t.float :weight
      t.references :item_group, foreign_key: true
      t.references :recipe_group, foreign_key: true
      t.references :ingredientable, polymorphic: true

      t.timestamps
    end
  end
end
