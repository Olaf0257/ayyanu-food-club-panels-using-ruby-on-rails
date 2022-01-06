class ChangeStartTimeToBeStringInMenuCategory < ActiveRecord::Migration[5.1]
  def change
  	  change_column :menu_categories, :start_time, :string
  	  change_column :menu_categories, :end_time, :string
  end
end
