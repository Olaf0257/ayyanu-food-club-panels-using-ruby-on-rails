class AddRefundColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    Privilege.create(privilege_name: "Refunds")
    add_column :orders, :refund, :boolean
    add_column :orders, :refund_notes, :text
  end
end
