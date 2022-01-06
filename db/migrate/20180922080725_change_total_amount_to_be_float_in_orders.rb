class ChangeTotalAmountToBeFloatInOrders < ActiveRecord::Migration[5.1]
  def change
  	  change_column :orders, :total_amount, :float
  end
end
