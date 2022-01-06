class AddAvailableToMenuCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_categories, :available, :boolean, null: false, default: true
    add_column :item_addon_categories, :available, :boolean, null: false, default: true
    add_column :item_addons, :available, :boolean, null: false, default: true
  end
end
