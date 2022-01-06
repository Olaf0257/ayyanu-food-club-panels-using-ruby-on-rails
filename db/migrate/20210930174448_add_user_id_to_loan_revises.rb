class AddUserIdToLoanRevises < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_revises, :user_id, :integer
  end
end
