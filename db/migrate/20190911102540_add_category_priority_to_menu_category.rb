class AddCategoryPriorityToMenuCategory < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_categories, :category_priority, :integer,default: 0
  	add_index :menu_categories,:category_priority
  end
end
