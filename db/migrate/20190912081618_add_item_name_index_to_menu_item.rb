class AddItemNameIndexToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_index :menu_items, :item_name
    add_index :menu_items, :item_name_ar
  end
end
