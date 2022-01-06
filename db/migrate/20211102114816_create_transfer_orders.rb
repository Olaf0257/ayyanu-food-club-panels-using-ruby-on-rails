class CreateTransferOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :transfer_orders do |t|
      t.references :country, foreign_key: true
      t.references :branch, foreign_key: true
      t.string :source_type
      t.integer :source_id
      t.string :destination_type
      t.integer :destination_id
      t.timestamp :delivery_date
      t.references :user, foreign_key: true
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
