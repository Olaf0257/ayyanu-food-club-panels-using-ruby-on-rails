class AddPositionToBranchCoverageAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :branch_coverage_areas, :position, :integer, null: false, default: 100
  end
end
