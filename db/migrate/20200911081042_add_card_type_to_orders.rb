class AddCardTypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :card_type, :string
  end
end
