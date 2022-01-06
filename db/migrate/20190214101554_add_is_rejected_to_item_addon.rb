class AddIsRejectedToItemAddon < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addons, :is_rejected, :boolean,default: false
    add_column :item_addons, :resion, :string
  end
end
