class AddCallCenterNumberToDeliveryCharges < ActiveRecord::Migration[5.2]
  def change
    add_column :delivery_charges, :call_center_number, :string
  end
end
