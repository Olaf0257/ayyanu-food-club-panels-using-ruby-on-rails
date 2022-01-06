class ChangeStartTimeToBeDatetimeInMenuCategories < ActiveRecord::Migration[5.1]
  def change
  	  change_column :menu_categories, :start_time, :datetime
  	  change_column :menu_categories, :end_time, :datetime
  end
end
