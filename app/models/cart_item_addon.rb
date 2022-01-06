class CartItemAddon < ApplicationRecord
  belongs_to :cart_item
  belongs_to :item_addon

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at]))
  end

  def self.create_cart_item_addons(cartItem, item_addons)
    addAddon = item_addons ? item_addons : []
    addAddon.each do |addon|
      create(item_addon_id: addon, cart_item_id: cartItem.id)
    end
  end

  def self.update_cart_addons(_cartItem, addons)
    addons.each do |addon|
      dbaAddon = find_by(id: addon)
      dbaAddon.update(add)
    end
  end
end
