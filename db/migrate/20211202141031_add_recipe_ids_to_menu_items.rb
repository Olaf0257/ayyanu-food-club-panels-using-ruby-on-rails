class AddRecipeIdsToMenuItems < ActiveRecord::Migration[5.2]
  def change
    add_column :menu_items, :recipe_ids, :text
  end
end
