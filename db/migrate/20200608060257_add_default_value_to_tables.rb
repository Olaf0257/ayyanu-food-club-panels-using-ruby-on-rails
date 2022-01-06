class AddDefaultValueToTables < ActiveRecord::Migration[5.1]
  def change
    DistanceDeliveryCharge.where(country_id: nil).update_all(country_id: 15)
    Contact.where(country_id: nil).update_all(country_id: 15)
    CoverageArea.where(country_id: nil).update_all(country_id: 15)
  end
end
