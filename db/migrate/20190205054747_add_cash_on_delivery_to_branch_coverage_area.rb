class AddCashOnDeliveryToBranchCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_column :branch_coverage_areas, :cash_on_delivery, :boolean,default: true
    add_column :branch_coverage_areas, :accept_cash, :boolean,default: false
    add_column :branch_coverage_areas, :accept_card, :boolean,default: false
  end
end
