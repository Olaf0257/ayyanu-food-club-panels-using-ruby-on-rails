class CreateMenuCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_categories do |t|
      t.string :category_title
      t.references :branch, foreign_key: true

      t.timestamps
    end
  end
end
