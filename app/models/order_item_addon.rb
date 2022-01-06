class OrderItemAddon < ApplicationRecord
  belongs_to :order_item
  belongs_to :item_addon

  def self.add_order_item_addon(orderItem, item)
    item.cart_item_addons.each do |addon|
      addon = create(order_item_id: orderItem.id, item_addon_id: addon.item_addon_id)
    end
  end
end
