class CreateEmployeeAssignTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :employee_assign_tasks do |t|
      t.integer :assign_task_id
      t.integer :employee_id
      t.integer :task_list_id
      t.string :assign_date_time
      t.boolean :is_completed
      t.timestamps
    end
  end
end
