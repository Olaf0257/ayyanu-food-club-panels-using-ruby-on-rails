class AddHsIdToMenuCategories < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :hs_id, :integer
  end
end
