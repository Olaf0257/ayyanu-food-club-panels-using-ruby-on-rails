class AddThirdPartyDeliveryColumnsToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :third_party_delivery, :boolean, null: false, default: false
    add_column :orders, :tax_percentage, :float
  end
end
