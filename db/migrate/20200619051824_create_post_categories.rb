class CreatePostCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :post_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
