class AddEmployeeId < ActiveRecord::Migration[5.2]
  def change
    add_column :reimbursements, :employee_id, :integer
  end
end
