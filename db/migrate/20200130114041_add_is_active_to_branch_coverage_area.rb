class AddIsActiveToBranchCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_column :branch_coverage_areas, :is_active, :boolean,default: false, index: true
  end
end
