class AddAddonAddonTitleArToItemAddon < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addons, :addon_title_ar, :string
  end
end
