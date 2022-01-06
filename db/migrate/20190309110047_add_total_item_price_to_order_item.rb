class AddTotalItemPriceToOrderItem < ActiveRecord::Migration[5.1]
  def change
    add_column :order_items, :total_item_price, :float,default: "0.000"
  end
end
