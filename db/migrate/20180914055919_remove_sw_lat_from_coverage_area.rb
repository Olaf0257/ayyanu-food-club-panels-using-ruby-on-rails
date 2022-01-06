class RemoveSwLatFromCoverageArea < ActiveRecord::Migration[5.1]
  def change
    remove_column :coverage_areas, :sw_lat, :string
    remove_column :coverage_areas, :sw_long, :string
    remove_column :coverage_areas, :ne_lat, :string
    remove_column :coverage_areas, :ne_long, :string
   end
end
