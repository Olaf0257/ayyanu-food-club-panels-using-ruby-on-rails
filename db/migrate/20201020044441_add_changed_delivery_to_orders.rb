class AddChangedDeliveryToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :changed_delivery, :boolean, null: false, default: false
  end
end
