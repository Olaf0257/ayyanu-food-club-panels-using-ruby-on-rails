class ChangeAmountToLoans < ActiveRecord::Migration[5.2]
  def change
    change_column :loans, :amount, :decimal, precision: 30, :scale => 3
    change_column :loans, :interest_rate, :decimal, precision: 30, :scale => 3
    change_column :loan_revises, :topup_amount, :decimal, precision: 30, :scale => 3
    change_column :loan_revises, :new_interest_rate, :decimal, precision: 30, :scale => 3
    change_column :loan_settlements, :remaining_amount, :decimal, precision: 30, :scale => 3
  end
end
