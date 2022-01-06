class AddStatusAndRejectedReasonToLoanSettlements < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_settlements, :status, :string
    add_column :loan_settlements, :rejected_reason, :string
    change_column :loan_settlements, :restaurant_id, :string
  end
end
