class AddRejectedReasonToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :purchase_orders, :rejected_reason, :text
  end
end
