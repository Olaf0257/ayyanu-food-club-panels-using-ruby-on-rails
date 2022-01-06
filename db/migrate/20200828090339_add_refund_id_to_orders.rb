class AddRefundIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :refund_id, :string
  end
end
