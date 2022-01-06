class CreateItemAddons < ActiveRecord::Migration[5.1]
  def change
    create_table :item_addons do |t|
      t.string :addon_title
      t.float :addon_price
      t.references :item_addon_category, foreign_key: true

      t.timestamps
    end
  end
end
