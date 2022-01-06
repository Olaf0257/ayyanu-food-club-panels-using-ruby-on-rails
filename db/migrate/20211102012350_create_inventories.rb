class CreateInventories < ActiveRecord::Migration[5.2]
  def change
    create_table :inventories do |t|
      t.belongs_to :article, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.belongs_to :restaurant, foreign_key: true
      t.float :stock
      t.references :inventoryable, polymorphic: true

      t.timestamps
    end
  end
end
