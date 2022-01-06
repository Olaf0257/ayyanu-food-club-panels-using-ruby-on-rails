class RemoveForeignKeyFromItemAdddonCategories < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :item_addon_categories, :menu_items
  end
end
