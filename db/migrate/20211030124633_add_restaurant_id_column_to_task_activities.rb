class AddRestaurantIdColumnToTaskActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :task_activities, :restaurant_id, :integer
  end
end
