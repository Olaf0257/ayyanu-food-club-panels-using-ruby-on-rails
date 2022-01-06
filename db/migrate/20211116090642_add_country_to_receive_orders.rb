class AddCountryToReceiveOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :receive_orders, :country, foreign_key: true
    add_reference :receive_orders, :branch, foreign_key: true
  end
end
