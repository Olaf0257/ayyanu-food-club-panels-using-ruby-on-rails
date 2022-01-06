class RemoveMinOrderAmountFromDeliveryCharge < ActiveRecord::Migration[5.2]
  def change
    remove_column :delivery_charges, :min_order_amount
  end
end
