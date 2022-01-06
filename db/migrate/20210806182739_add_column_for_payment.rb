class AddColumnForPayment < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_payments, :pending_delete, :boolean, default: false
    add_column :pos_checks, :saved_at, :datetime
  end
end
