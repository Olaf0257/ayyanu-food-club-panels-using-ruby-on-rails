class AddStationIdsToRecipes < ActiveRecord::Migration[5.2]
  def change
    add_column :recipes, :station_ids, :text
  end
end
