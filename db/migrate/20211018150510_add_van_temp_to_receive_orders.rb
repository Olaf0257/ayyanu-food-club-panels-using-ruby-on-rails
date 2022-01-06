class AddVanTempToReceiveOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :receive_orders, :van_temp, :string
  end
end
