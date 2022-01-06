class CreateEventCountries < ActiveRecord::Migration[5.2]
  def change
    create_table :event_countries do |t|
      t.references :event, null: false, foreign_key: true, index: true
      t.references :country, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
