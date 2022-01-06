class CreateTaskLists < ActiveRecord::Migration[5.2]
  def change
    create_table :task_lists do |t|
      t.string :name
      t.integer :country_id
      t.string :location
      t.integer :task_type_id
      t.integer :task_category_id
      t.integer :task_activity_id
      t.integer :restaurant_id
      t.integer :created_by_id

      t.timestamps
    end
  end
end
