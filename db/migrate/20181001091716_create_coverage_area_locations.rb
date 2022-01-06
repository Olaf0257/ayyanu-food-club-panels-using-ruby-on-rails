class CreateCoverageAreaLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :coverage_area_locations do |t|
      t.string :latitude
      t.string :longitude
      t.references :coverage_area, foreign_key: true

      t.timestamps
    end
  end
end
