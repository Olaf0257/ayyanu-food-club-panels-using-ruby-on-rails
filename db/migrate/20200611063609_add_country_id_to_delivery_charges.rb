class AddCountryIdToDeliveryCharges < ActiveRecord::Migration[5.2]
  def change
    add_reference :delivery_charges, :country, foreign_key: true, index: true
    DeliveryCharge.update_all(country_id: 15)
  end
end
