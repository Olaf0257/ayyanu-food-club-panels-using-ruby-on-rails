class AddColumnSeatNoToPosTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_transactions, :seat_no, :integer
    add_column :pos_tables, :current_seat_no, :integer, default: 1
    add_column :pos_tables, :table_status, :integer, default: 0
  end
end
