class AddRefundFaultToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :refund_fault, :string
  end
end
