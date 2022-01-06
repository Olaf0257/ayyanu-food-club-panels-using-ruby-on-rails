class AddKitchenInstructionsToPosTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :kitchen_instructions, :text
  end
end
