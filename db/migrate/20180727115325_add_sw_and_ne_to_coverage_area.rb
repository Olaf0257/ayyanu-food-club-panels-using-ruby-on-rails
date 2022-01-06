class AddSwAndNeToCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_column :coverage_areas, :sw_lat, :string
    add_column :coverage_areas, :sw_long, :string
    add_column :coverage_areas, :ne_lat, :string
    add_column :coverage_areas, :ne_long, :string
  end
end
