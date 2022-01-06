class AddDeliveryChargeToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :delivery_charge, :float,default: "0.000"
    add_column :orders, :tax_amount, :float,default: "0.000"
  end
end
