class CreateLoanRevises < ActiveRecord::Migration[5.2]
  def change
    create_table :loan_revises do |t|
      t.decimal :topup_amount
      t.integer :loan_period
      t.decimal :new_interest_rate

      t.timestamps
    end
  end
end
