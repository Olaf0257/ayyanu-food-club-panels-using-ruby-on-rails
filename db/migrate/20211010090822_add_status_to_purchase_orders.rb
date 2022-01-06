class AddStatusToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :purchase_orders, :status, :integer, default: 0
  end
end
