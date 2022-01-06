class CreateShiftDates < ActiveRecord::Migration[5.2]
  def change
    create_table :shift_dates do |t|
      t.integer :shift_id
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
