class AddDeliveryServiceToDistanceDeliveryCharges < ActiveRecord::Migration[5.2]
  def change
    add_column :distance_delivery_charges, :delivery_service, :float, null: false, default: 0
  end
end
