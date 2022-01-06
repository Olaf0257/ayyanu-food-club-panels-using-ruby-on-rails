class AddMinOrderAmountToDistanceDeliveryCharges < ActiveRecord::Migration[5.2]
  def change
    add_column :distance_delivery_charges, :min_order_amount, :float, null: false, default: 0
  end
end
