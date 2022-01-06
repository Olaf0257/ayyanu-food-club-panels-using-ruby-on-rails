class AddColumnTimeToAndTimeFromToTaskList < ActiveRecord::Migration[5.2]
  def change
    add_column :task_lists, :time_to, :datetime
    add_column :task_lists, :time_from, :datetime
  end
end
