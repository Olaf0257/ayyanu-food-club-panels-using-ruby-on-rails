class AddThirdPartyFieldsToBranchCoverageAreas < ActiveRecord::Migration[5.1]
  def change
    add_column :branch_coverage_areas, :third_party_delivery, :boolean, null: false, default: false
    add_column :branch_coverage_areas, :third_party_delivery_type, :string
  end
end
