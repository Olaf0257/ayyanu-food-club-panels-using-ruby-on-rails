class CreateLoanSettlements < ActiveRecord::Migration[5.2]
  def change
    create_table :loan_settlements do |t|
      t.decimal :remaining_amount
      t.string  :payment_mode
      t.date    :when_to_settle_date
      t.integer :restaurant_id
      t.timestamps
    end
  end
end
