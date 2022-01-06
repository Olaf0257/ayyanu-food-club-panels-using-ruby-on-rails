class CreateTaskSubCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :task_sub_categories do |t|
      t.integer :restaurant_id
      t.string :location
      t.integer :task_type_id
      t.integer :task_category_id
      t.integer :created_by_id
      t.integer :country_id
      t.string :name
      t.timestamps
    end
  end
end
