class AddSharedCheckId < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :shared_transaction_id, :integer, default: false
  end
end
