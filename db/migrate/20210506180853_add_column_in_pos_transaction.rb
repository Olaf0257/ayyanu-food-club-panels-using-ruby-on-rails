class AddColumnInPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :comments, :text
  end
end
