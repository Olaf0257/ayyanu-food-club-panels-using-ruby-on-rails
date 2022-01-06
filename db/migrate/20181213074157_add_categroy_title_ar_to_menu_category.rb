class AddCategroyTitleArToMenuCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :categroy_title_ar, :string
  end
end
