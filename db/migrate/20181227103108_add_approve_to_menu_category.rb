class AddApproveToMenuCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :approve, :boolean, default: true
  end
end
