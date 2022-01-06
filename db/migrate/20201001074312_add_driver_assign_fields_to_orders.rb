class AddDriverAssignFieldsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :driver_assigned_at, :datetime
    add_column :orders, :driver_accepted_at, :datetime
  end
end
