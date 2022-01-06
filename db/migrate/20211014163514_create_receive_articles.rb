class CreateReceiveArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :receive_articles do |t|
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true
      t.references :store, foreign_key: true
      t.references :article, foreign_key: true
      t.references :receive_order, foreign_key: true
      t.timestamp :expiry
      t.float :quantity
      t.float :rate
      t.float :net_amount
      t.float :vat
      t.float :total

      t.timestamps
    end
  end
end
