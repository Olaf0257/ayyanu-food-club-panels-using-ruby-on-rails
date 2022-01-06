class AddLocationFieldsToCoverageAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :coverage_areas, :location, :string
    add_column :coverage_areas, :latitude, :string
    add_column :coverage_areas, :longitude, :string
  end
end
