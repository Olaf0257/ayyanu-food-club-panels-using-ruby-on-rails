class AddStatusToReceiveOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :receive_orders, :status, :integer, default: 0
    add_column :receive_orders, :rejected_reason, :text
  end
end
