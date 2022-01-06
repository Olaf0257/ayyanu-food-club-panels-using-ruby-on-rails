class AddDineInToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :dine_in, :boolean, null: false, default: false
    add_column :orders, :table_number, :string
  end
end
