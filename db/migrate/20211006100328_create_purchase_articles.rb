class CreatePurchaseArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :purchase_articles do |t|
      t.references :purchase_order, foreign_key: true
      t.references :article, foreign_key: true
      t.references :user, foreign_key: true
      t.references :restaurant, foreign_key: true
      t.integer :quantity
      t.float :net_amount

      t.timestamps
    end
  end
end
