class CreateMenuItemAddonCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_item_addon_categories do |t|
      t.references :item_addon_category, foreign_key: true
      t.references :menu_item, foreign_key: true

      t.timestamps
    end
  end
end
