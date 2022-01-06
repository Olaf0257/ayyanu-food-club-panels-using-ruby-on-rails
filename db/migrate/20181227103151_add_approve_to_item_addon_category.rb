class AddApproveToItemAddonCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addon_categories, :approve,  :boolean, default: true
end
end
