class CreateReceiveOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :receive_orders do |t|
      t.references :restaurant, foreign_key: true
      t.references :user, foreign_key: true
      t.references :store, foreign_key: true
      t.references :vendor, foreign_key: true
      t.timestamp :delivery_date
      t.string :invoice_no
      t.float :subtotal
      t.float :total_vat_amount
      t.float :total

      t.timestamps
    end
  end
end
