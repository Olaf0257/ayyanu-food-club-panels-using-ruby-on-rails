class RenameDepartmentToDepartmentId < ActiveRecord::Migration[5.2]
  def change
    remove_column :user_details, :department
    add_column :user_details, :department_id, :integer
    add_column :users, :cpr_number_expiry, :date
  end
end
