class AddLocationColumnToTaskActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :task_activities, :location, :string
  end
end
