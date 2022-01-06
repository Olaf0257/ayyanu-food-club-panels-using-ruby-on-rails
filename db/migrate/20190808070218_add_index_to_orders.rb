class AddIndexToOrders < ActiveRecord::Migration[5.1]
  def change
  	add_index :orders, :transporter_id
  end
end
