class RenameDepartmentIdToLoans < ActiveRecord::Migration[5.2]
  def change
    rename_column :loans, :department_id, :department
    rename_column :loans, :designation_id, :designation

    change_column :loans, :department, :string
    change_column :loans, :designation, :string
  end
end
