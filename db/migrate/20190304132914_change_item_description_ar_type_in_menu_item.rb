class ChangeItemDescriptionArTypeInMenuItem < ActiveRecord::Migration[5.1]
  def change
  	change_column :menu_items, :item_description_ar, :text
  end
end
