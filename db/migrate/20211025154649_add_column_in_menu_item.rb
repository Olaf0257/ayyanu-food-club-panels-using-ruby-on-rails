class AddColumnInMenuItem < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :preparation_time, :integer, default: 15
    add_column :item_addons, :preparation_time, :integer, default: 15
  end
end
