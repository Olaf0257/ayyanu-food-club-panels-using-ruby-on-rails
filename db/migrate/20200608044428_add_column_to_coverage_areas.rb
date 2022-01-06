class AddColumnToCoverageAreas < ActiveRecord::Migration[5.1]
  def change
    add_column :coverage_areas, :country_id, :integer
  end
end
