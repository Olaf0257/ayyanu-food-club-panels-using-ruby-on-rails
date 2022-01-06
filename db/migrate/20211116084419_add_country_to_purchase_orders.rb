class AddCountryToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :purchase_orders, :country, foreign_key: true
    add_reference :purchase_orders, :branch, foreign_key: true
  end
end
