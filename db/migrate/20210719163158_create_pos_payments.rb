class CreatePosPayments < ActiveRecord::Migration[5.2]
  def change
    create_table :pos_payments do |t|
      t.references :payment_method, foreign_key: true
      t.references :pos_check, foreign_key: true
      t.float :amount
      t.float :discounted_amount
      t.float :paid_amount
      t.string :method_reference
      t.string :reference_number

      t.timestamps
    end
  end
end
