class Adddefaulvaluetocolumn < ActiveRecord::Migration[5.2]
  def change
  	change_column :employee_assign_tasks, :is_completed, :boolean, :default => false
  end
end
