class AddmenuitemidstoMenuItem < ActiveRecord::Migration[5.2]
  def change
  	add_column :menu_items, :menu_item_ids, :string
  end
end
