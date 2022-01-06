class AddCancelReasonToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :cancel_reason, :text
  end
end
