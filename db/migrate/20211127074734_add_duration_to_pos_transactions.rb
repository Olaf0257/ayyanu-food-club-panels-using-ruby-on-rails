class AddDurationToPosTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :duration, :integer
  end
end
