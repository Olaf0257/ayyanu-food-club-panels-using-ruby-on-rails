class CreateMenuItems < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_items do |t|
      t.string :item_name
      t.string :item_rating
      t.float :price_per_item
      t.string :item_image
      t.string :item_description
      t.references :menu_category, foreign_key: true

      t.timestamps
    end
  end
end
