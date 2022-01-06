class AddVatPriceToCartItem < ActiveRecord::Migration[5.1]
  def change
    add_column :cart_items, :vat_price, :float,default: 0.000, index: true
  end
end
