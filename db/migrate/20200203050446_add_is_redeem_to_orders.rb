class AddIsRedeemToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :is_redeem, :boolean,default: false
    add_column :orders, :used_point, :float
  end
end
