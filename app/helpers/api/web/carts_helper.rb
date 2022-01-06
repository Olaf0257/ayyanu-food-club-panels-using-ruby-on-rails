module Api::Web::CartsHelper
  def web_cart_list_json(items)
    items.as_json(only: [:id, :quantity, :description])
  end

  def get_web_cart_item_total_price(cart)
    total_price = 0
    total_quantity = 0
    sub_total = 0
    pricePerItem = 0
    items = cart.cart_items
    items.each do |item|
      offerPercentage = item.menu_item.offer
      basePrice = item.menu_item.price_per_item
      quantity = item.quantity
      total_quantity += quantity.to_i
      addOn = 0
      item.cart_item_addons&.each do |addon|
        addonPrice = addon.item_addon.addon_price
        addOn += addonPrice
      end

      sub_total = (sub_total + (basePrice.to_f * quantity.to_i) + (quantity.to_i * addOn))
      total_price =  (sub_total + cart.branch.delivery_charges.to_f)
      pricePerItem = basePrice.to_f + addOn
    end
    { total_price: helpers.number_with_precision(total_price, precision: 3), sub_total: helpers.number_with_precision(sub_total, precision: 3), price_per_item: pricePerItem, total_quantity: total_quantity, tax_percentage: cart.branch.tax_percentage ? cart.branch.tax_percentage : 0.0, delivery_charges: cart.branch.delivery_charges.to_f, cash_on_delivery: cart.branch.cash_on_delivery, accept_card: cart.branch.accept_card, restaurant_name: cart.branch ? cart.branch.restaurant_name : "", branch_id: cart ? cart.branch.id : 0, address: cart ? cart.branch.address : "", min_order_amount: cart ? cart.branch.min_order_amount : 0 }
    rescue Exception => e
  end
end
