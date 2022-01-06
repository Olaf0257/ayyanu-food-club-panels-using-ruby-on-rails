class AddColumnsToManuItemAndAddon < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :include_in_pos, :boolean, default: true
    add_column :menu_items, :include_in_app, :boolean, default: true
    add_column :item_addons, :include_in_pos, :boolean, default: true
    add_column :item_addons, :include_in_app, :boolean, default: true
  end
end
