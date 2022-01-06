class CreateStations < ActiveRecord::Migration[5.2]
  def change
    create_table :stations do |t|
      t.string :name
      t.references :restaurant, foreign_key: true
      t.references :branch, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
