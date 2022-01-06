class AddStatusToTransferOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :transfer_orders, :status, :integer, default: 0
  end
end
