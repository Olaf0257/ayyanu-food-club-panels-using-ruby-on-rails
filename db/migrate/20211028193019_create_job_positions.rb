class CreateJobPositions < ActiveRecord::Migration[5.2]
  def change
    create_table :job_positions do |t|
      t.string :title
      t.integer :department_id
      t.integer :designation_id
      t.string :candidate_name
      t.string :location
      t.integer :number_of_rounds
      t.string :status
      t.integer :created_by_id
      t.string :requirement_responsibility
      t.integer :expected_employees
      t.text :job_description
      t.string :name_of_rounds
      t.integer :country_id
      t.integer :restaurant_id

      t.timestamps
    end
  end
end
