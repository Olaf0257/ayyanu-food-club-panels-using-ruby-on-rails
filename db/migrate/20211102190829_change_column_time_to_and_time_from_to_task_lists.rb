class ChangeColumnTimeToAndTimeFromToTaskLists < ActiveRecord::Migration[5.2]
  def change
    change_column :task_lists, :time_to, :string
    change_column :task_lists, :time_from, :string
  end
end
