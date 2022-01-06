class AddFarMenuToMenuItems < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :far_menu, :boolean, null: false, default: true
  end
end
