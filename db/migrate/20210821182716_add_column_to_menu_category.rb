class AddColumnToMenuCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_categories, :include_in_pos, :boolean, default: true
    add_column :menu_categories, :include_in_app, :boolean, default: true
  end
end
