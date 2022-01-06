class AddPortionUnitToIngredient < ActiveRecord::Migration[5.2]
  def change
    add_column :ingredients, :portion_unit, :string
  end
end
