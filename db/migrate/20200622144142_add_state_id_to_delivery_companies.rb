class AddStateIdToDeliveryCompanies < ActiveRecord::Migration[5.2]
  def change
    add_reference :delivery_companies, :state, foreign_key: true, index: true
  end
end
