class AddIsRejectedToItemAddonCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addon_categories, :is_rejected, :boolean,default: false
     add_column :item_addon_categories, :resion, :string
  end
end
