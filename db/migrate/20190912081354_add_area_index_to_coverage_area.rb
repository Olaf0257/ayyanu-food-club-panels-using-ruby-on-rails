class AddAreaIndexToCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_index :coverage_areas, :area
  end
end
