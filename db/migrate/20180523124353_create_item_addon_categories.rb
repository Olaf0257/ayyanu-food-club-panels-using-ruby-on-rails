class CreateItemAddonCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :item_addon_categories do |t|
      t.string :addon_category_name
      t.string :min_selected_quantity
      t.string :max_selected_quantity
      t.references :menu_item, foreign_key: true

      t.timestamps
    end
  end
end
