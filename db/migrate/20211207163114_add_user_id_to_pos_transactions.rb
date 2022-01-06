class AddUserIdToPosTransactions < ActiveRecord::Migration[5.2]
  def change
    # add_column :pos_checks, :user_id, :integer
    add_column :pos_unsaved_transactions, :user_id, :integer
  end
end
