class AddCountryToComboMealGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :combo_meal_groups, :country, foreign_key: true
    add_column :combo_meal_groups, :branch_ids, :string
  end
end
