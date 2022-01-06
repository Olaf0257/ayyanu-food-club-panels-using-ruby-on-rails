class CreateCateringSchedules < ActiveRecord::Migration[5.2]
  def change
    create_table :catering_schedules do |t|
      t.references :pos_check, foreign_key: true
      t.references :branch, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.datetime :executed_at
      t.string :job_id

      t.timestamps
    end
  end
end
