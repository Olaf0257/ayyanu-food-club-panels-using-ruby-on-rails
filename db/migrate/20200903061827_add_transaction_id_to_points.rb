class AddTransactionIdToPoints < ActiveRecord::Migration[5.2]
  def change
    add_column :points, :transaction_id, :string
    add_column :users, :pending_amount, :float, null: false, default: 0
  end
end
