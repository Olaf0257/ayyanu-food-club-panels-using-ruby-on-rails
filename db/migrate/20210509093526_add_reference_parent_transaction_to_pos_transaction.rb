class AddReferenceParentTransactionToPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :parent_pos_transaction_id, :integer
  end
end
