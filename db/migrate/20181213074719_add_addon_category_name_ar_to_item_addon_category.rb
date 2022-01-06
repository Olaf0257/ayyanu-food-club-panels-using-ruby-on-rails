class AddAddonCategoryNameArToItemAddonCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :item_addon_categories, :addon_category_name_ar, :string
  end
end
