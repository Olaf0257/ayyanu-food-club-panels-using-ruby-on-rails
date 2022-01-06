class AddIsRejectedToMenuCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :is_rejected, :boolean,default: false
    add_column :menu_categories, :resion, :string
  end
end
