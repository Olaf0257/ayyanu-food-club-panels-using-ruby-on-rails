class AddCalorieToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :calorie, :float,default: "0.000"
  end
end
