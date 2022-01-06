class AddCreatedByIdToLoanRevises < ActiveRecord::Migration[5.2]
  def change
    add_column :loans, :created_by_id, :integer
    add_column :loan_revises, :restaurant_id, :integer
    add_column :loans, :status, :string
    add_column :loans, :rejected_reason, :string
  end
end
