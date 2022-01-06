class AddTransferrableAmountToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :transferrable_amount, :float
  end
end
