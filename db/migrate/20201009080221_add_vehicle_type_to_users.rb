class AddVehicleTypeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :vehicle_type, :boolean
  end
end
