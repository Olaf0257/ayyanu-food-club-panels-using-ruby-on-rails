class AddCancelledColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :is_cancelled, :boolean, null: false, default: false
    add_column :orders, :cancelled_at, :datetime
    add_column :orders, :cancellation_reason, :string
  end
end
