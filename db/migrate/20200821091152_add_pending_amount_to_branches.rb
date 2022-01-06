class AddPendingAmountToBranches < ActiveRecord::Migration[5.2]
  def change
    add_column :branches, :pending_amount, :float, null: false, default: 0
  end
end
