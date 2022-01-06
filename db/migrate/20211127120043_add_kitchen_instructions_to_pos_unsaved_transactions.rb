class AddKitchenInstructionsToPosUnsavedTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_unsaved_transactions, :kitchen_instructions, :text
    add_column :pos_unsaved_transactions, :duration, :integer
  end
end
