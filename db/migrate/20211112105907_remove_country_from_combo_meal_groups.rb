class RemoveCountryFromComboMealGroups < ActiveRecord::Migration[5.2]
  def change
    remove_reference :combo_meal_groups, :country, foreign_key: true
    add_column :combo_meal_groups, :country_ids, :text
  end
end
