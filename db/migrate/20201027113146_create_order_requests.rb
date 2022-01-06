class CreateOrderRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :order_requests do |t|
      t.float :base_price, null: false, default: 0
      t.float :vat_price, null: false, default: 0
      t.float :service_charge, null: false, default: 0
      t.float :total_amount, null: false, default: 0
      t.string :mobile, null: false, default: ""
      t.references :branch, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
