class CreateTransferArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :transfer_articles do |t|
      t.references :transfer_order, foreign_key: true
      t.references :inventory, foreign_key: true
      t.references :article, foreign_key: true
      t.float :quantity
      t.references :user, foreign_key: true
      t.references :restaurant, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
