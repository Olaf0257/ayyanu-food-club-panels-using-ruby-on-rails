class CreateJobOpenings < ActiveRecord::Migration[5.2]
  def change
    create_table :job_openings do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :total_experience
      t.string :resume_file
      t.string :status, default: "pending"
      t.integer :country_id
      t.integer :job_position_id

      t.timestamps
    end
  end
end
