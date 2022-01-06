class AddOrderCancelColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :cancel_request_by, :string
    add_column :orders, :cancel_notes, :text
  end
end
