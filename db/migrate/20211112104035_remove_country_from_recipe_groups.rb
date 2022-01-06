class RemoveCountryFromRecipeGroups < ActiveRecord::Migration[5.2]
  def change
    remove_reference :recipe_groups, :country, foreign_key: true
    add_column :recipe_groups, :country_ids, :text
  end
end
