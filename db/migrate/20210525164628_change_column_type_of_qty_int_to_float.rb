class ChangeColumnTypeOfQtyIntToFloat < ActiveRecord::Migration[5.2]
  def change
  	 change_column :pos_transactions, :qty, :float
  end
end
