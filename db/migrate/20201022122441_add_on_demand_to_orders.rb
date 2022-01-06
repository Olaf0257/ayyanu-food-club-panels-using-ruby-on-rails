class AddOnDemandToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :on_demand, :boolean, null: false, default: false
  end
end
