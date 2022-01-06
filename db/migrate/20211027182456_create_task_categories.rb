class CreateTaskCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :task_categories do |t|
      t.string :category_name
      t.integer :country_id
      t.integer :area_id
      t.integer :restaurant_id
      t.integer :created_by_id
      t.integer :task_type_id
      t.string :location
      t.timestamps
    end
  end
end
