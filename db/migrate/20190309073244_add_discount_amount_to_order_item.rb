class AddDiscountAmountToOrderItem < ActiveRecord::Migration[5.1]
  def change
    add_column :order_items, :discount_amount, :float,default: 0.000
  end
end
