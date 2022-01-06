class AddUserToLoanSettlement < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_settlements, :user_id, :integer
    add_column :loan_settlements, :loan_id, :integer
  end
end
