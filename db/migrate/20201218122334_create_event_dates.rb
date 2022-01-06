class CreateEventDates < ActiveRecord::Migration[5.2]
  def change
    create_table :event_dates do |t|
      t.references :event, null: false, foreign_key: true, index: true
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end
  end
end
