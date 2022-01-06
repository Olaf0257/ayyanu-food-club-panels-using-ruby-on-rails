class CreateOrderTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :order_taxes do |t|
      t.string :name, null: false
      t.float :percentage, null: false
      t.float :amount, null: false
      t.references :order, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
