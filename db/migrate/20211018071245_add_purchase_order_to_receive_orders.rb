class AddPurchaseOrderToReceiveOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :receive_orders, :purchase_order, foreign_key: true
  end
end
