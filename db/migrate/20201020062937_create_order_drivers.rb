class CreateOrderDrivers < ActiveRecord::Migration[5.2]
  def change
    create_table :order_drivers do |t|
      t.datetime :driver_assigned_at
      t.datetime :driver_accepted_at
      t.references :order, foreign_key: true, null: false
      t.integer :transporter_id, null: false

      t.timestamps
    end

    add_index :order_drivers, :transporter_id
  end
end
