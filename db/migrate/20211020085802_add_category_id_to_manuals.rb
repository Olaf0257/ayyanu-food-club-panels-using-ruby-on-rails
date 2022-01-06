class AddCategoryIdToManuals < ActiveRecord::Migration[5.2]
  def change
    add_column :manuals, :manual_category_id, :integer
  end
end
