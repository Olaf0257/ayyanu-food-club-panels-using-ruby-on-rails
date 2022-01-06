class AddStationIdsToMenuItems < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :station_ids, :text
  end
end
