class CreateScheduleShifts < ActiveRecord::Migration[5.2]
  def change
    create_table :schedule_shifts do |t|
      t.integer :shift_id
      t.integer :station_id
      t.string :employee_ids
      t.integer :restaurant_id
      t.string :day_name

      t.timestamps
    end
  end
end
