class AddApprovedAtToDeliveryCompanies < ActiveRecord::Migration[5.2]
  def change
    add_column :delivery_companies, :approved_at, :datetime
    add_column :delivery_companies, :rejected_at, :datetime
  end
end
