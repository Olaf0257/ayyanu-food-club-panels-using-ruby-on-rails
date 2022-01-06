class CreatePurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :purchase_orders do |t|
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true
      t.references :store, foreign_key: true
      t.references :vendor, foreign_key: true
      t.references :unit, foreign_key: true
      t.references :article, foreign_key: true
      t.timestamp :delivery_date

      t.timestamps
    end
  end
end
