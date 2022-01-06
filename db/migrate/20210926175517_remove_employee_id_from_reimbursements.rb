class RemoveEmployeeIdFromReimbursements < ActiveRecord::Migration[5.2]
  def change
    remove_column :reimbursements, :employee_id, :string
    add_column :reimbursements, :restaurant_id, :string
    add_column :reimbursements, :rejected_reason, :string
  end
end
