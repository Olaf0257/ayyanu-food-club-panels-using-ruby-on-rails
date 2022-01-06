class AddItemNameArToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :item_name_ar, :string
    add_column :menu_items, :item_description_ar, :string
  end
end
