class AddStationIdsToMenuCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_categories, :station_ids, :text
  end
end
