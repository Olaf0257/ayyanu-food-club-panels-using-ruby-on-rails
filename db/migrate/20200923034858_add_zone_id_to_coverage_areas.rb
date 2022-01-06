class AddZoneIdToCoverageAreas < ActiveRecord::Migration[5.2]
  def change
    add_reference :coverage_areas, :zone, foreign_key: true, index: true
  end
end
