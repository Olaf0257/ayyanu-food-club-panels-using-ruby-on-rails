class CreateBranchPayments < ActiveRecord::Migration[5.2]
  def change
    create_table :branch_payments do |t|
      t.float :amount, null: false
      t.string :transaction_id, null: false
      t.references :branch, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
