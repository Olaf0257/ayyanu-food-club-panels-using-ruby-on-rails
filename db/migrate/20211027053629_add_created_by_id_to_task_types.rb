class AddCreatedByIdToTaskTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :task_types, :created_by_id, :integer
  end
end
