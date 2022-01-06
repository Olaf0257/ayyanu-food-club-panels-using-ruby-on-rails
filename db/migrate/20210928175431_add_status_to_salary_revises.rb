class AddStatusToSalaryRevises < ActiveRecord::Migration[5.2]
  def change
    add_column :loan_revises, :status, :string
    change_column :loan_revises, :restaurant_id, :string
    add_column :loan_revises, :loan_id, :integer
  end
end
