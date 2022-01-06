class AddColumnToPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :transaction_status, :integer, default: 0
  end
end
