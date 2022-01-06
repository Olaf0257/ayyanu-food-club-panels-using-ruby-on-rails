class AddChangedFieldsToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :changed_column_name, :string
    add_column :menu_items, :changed_column_name, :string
    add_column :item_addon_categories, :changed_column_name, :string
    add_column :item_addons, :changed_column_name, :string
  end
end
