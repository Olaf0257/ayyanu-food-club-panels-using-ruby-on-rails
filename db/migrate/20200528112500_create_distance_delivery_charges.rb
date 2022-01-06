class CreateDistanceDeliveryCharges < ActiveRecord::Migration[5.1]
  def change
    create_table :distance_delivery_charges do |t|
      t.float :min_distance, null: false, default: 0
      t.float :max_distance, null: false, default: 0
      t.float :charge, null: false, default: 0

      t.timestamps
    end
  end
end
