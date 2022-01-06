class AddPaymentApprovedColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :payment_approval_pending, :boolean, null: false, default: false
    add_column :orders, :payment_approved_at, :datetime
    add_column :orders, :payment_rejected_at, :datetime
    add_column :orders, :payment_reject_reason, :string
  end
end
