class AddPortionColumnsToRecipe < ActiveRecord::Migration[5.2]
  def change
    add_column :recipes, :portion, :string
    add_column :recipes, :portion_size, :string
  end
end
