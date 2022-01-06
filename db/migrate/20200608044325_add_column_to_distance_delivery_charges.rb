class AddColumnToDistanceDeliveryCharges < ActiveRecord::Migration[5.1]
  def change
    add_column :distance_delivery_charges, :country_id, :integer
  end
end
