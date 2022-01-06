class AddApproveToMenuItem < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :approve, :boolean, default: true
  end
end
