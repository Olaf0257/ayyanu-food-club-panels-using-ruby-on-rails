class AddColumnsToPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_tables, :is_dine_in, :boolean, default: true
    add_reference :pos_transactions, :pos_check, index:true
  end
end
