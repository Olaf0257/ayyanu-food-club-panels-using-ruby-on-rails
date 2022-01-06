class AddBranchToItemAddonCategories < ActiveRecord::Migration[5.1]
  def change
    add_reference :item_addon_categories, :branch, foreign_key: true
  end
end
