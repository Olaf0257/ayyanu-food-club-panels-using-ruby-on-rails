class AddCountryToRecipeGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :recipe_groups, :country, foreign_key: true
    add_column :recipe_groups, :branch_ids, :string
  end
end
