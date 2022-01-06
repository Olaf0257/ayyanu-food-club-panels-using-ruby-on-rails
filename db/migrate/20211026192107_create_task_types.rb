class CreateTaskTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :task_types do |t|
      t.string :name
      t.integer :country_id
      t.integer :area_id
      t.integer :restaurant_id
      t.timestamps
    end
  end
end
