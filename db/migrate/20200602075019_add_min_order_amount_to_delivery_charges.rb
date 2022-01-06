class AddMinOrderAmountToDeliveryCharges < ActiveRecord::Migration[5.1]
  def change
    add_column :delivery_charges, :min_order_amount, :float, null: false, default: 0
  end
end
