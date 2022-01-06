class ChangeFooddeliveryChargesToFoodclubCharges < ActiveRecord::Migration[5.1]
  def change
  	rename_column :branch_coverage_areas, :fooddelivey_charges, :foodclub_charges
  end
end
