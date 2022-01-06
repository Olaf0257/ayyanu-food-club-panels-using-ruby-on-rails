class AddColumnInCashType < ActiveRecord::Migration[5.2]
  def change
    add_column :cash_types, :pos_cash_type, :string
    add_column :cash_types, :converted_amount, :float
  end
end
