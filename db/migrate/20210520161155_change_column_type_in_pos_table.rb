class ChangeColumnTypeInPosTable < ActiveRecord::Migration[5.2]
  def change
    remove_column :pos_tables, :name, :string
    add_column :pos_tables, :pos_table_no, :integer
  end
end
