class AddLocationToTaskType < ActiveRecord::Migration[5.2]
  def change
    add_column :task_types, :location, :string
    # add_column :task_types, :country_id, :integer
  end
end
