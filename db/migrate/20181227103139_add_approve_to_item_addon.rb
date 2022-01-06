class AddApproveToItemAddon < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addons, :approve, :boolean, default: true
  end
end
