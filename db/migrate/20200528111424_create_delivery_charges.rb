class CreateDeliveryCharges < ActiveRecord::Migration[5.1]
  def change
    create_table :delivery_charges do |t|
      t.float :delivery_percentage, null: false, default: 0

      t.timestamps
    end

    DeliveryCharge.create(delivery_percentage: 10)
  end
end
