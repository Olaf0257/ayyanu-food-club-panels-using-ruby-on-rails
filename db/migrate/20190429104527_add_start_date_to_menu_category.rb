class AddStartDateToMenuCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :start_date, :date
    add_column :menu_categories, :end_date, :date
    add_column :menu_categories, :start_time, :time
    add_column :menu_categories, :end_time, :time
  end
end
