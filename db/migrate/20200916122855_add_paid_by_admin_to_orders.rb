class AddPaidByAdminToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :paid_by_admin, :boolean, null: false, default: false
    add_column :orders, :paid_by_admin_at, :datetime
  end
end
