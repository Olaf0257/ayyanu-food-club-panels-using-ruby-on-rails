class AddRejectedReasonToLoanRevises < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_revises, :rejected_reason, :string
    add_column :loans, :original_amount, :decimal
  end
end
