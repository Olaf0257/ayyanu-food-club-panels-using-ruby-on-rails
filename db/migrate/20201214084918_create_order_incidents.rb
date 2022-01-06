class CreateOrderIncidents < ActiveRecord::Migration[5.2]
  def change
    create_table :order_incidents do |t|
      t.integer :reported_by, null: false
      t.integer :created_by, null: false
      t.string :complaint_on, null: false
      t.string :item_type, null: false
      t.string :complaint_description
      t.boolean :refund_required, null: false, default: false
      t.string :witness_name
      t.string :witness_number
      t.string :witness_description
      t.references :order, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
