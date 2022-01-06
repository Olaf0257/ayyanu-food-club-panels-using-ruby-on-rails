class CreateTaskActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :task_activities do |t|
      t.integer :country_id
      t.integer :task_type_id
      t.integer :task_category_id
      t.string :name
      t.integer :created_by_id
      t.string :location_ids

      t.timestamps
    end
  end
end
