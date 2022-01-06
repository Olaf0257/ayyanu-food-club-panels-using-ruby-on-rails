class AddRejectReasonToDeliveryCompanies < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_companies, :reject_reason, :string
  end
end
