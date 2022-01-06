class AddIsRejectedToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :is_rejected, :boolean,default: false
    add_column :menu_items, :resion, :string
  end
end
