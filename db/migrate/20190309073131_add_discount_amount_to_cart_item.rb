class AddDiscountAmountToCartItem < ActiveRecord::Migration[5.1]
  def change
    add_column :cart_items, :discount_amount, :float,default: 0.000
  end
end
