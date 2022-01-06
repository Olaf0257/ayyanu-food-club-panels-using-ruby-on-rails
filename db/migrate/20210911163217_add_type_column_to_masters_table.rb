class AddTypeColumnToMastersTable < ActiveRecord::Migration[5.2]
  def change
    add_column :over_groups, :operation_type, :string
    add_column :major_groups, :operation_type, :string
    add_column :item_groups, :operation_type, :string
  end
end
