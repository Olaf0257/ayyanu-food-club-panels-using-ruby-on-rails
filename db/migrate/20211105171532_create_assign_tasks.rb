class CreateAssignTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :assign_tasks do |t|
      t.string :country_ids
      t.string :branch_ids
      t.string :department_ids
      t.string :designation_ids
      t.string :employee_ids
      t.string :task_list_ids
      t.string :restaurant_id
      t.string :assign_date_time
      t.integer :created_by_id

      t.timestamps
    end
  end
end
