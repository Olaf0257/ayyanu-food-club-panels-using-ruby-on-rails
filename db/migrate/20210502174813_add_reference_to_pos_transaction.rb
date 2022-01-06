class AddReferenceToPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_reference :pos_transactions, :pos_table, foreign_key: true
  end
end
