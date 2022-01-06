class AddFarMenuToBranchCoverageAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :branch_coverage_areas, :far_menu, :boolean, null: false, default: true
  end
end
