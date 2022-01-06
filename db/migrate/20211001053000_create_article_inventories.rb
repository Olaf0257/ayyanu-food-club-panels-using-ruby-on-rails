class CreateArticleInventories < ActiveRecord::Migration[5.2]
  def change
    create_table :article_inventories do |t|
      t.references :article, foreign_key: true
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true
      t.float :qty
      t.float :price
      t.float :last_price
      t.float :net_amount

      t.timestamps
    end
  end
end
