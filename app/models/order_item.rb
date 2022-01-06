class OrderItem < ApplicationRecord
  belongs_to :menu_item
  belongs_to :order
  has_many :order_item_addons, dependent: :destroy
  has_many :item_addons, through: :order_item_addons
  after_destroy :remove_order

  scope :available_menu_items, -> { joins(menu_item: :menu_category).where("menu_categories.approve = ? and menu_categories.available = true and menu_items.approve = ? and menu_items.is_available = (?) and (DATE(start_date) IS NULL or TIME(end_time) IS NULL) or (DATE(start_date) <= ? and DATE(end_date) >= ? and start_time <= ? and end_time > ?)", true, true, true, Date.today, Date.today, Time.now, Time.now).uniq }

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at]))
  end

  def self.add_order_items(cart, order, totalAmount, is_redeem)
    if order.id
      cart.cart_items.each do |item|
        orderItem = create(quantity: item.quantity, description: item.description, menu_item_id: item.menu_item_id, order_id: order.id, discount_amount: item.discount_amount, total_item_price: item.total_item_price, vat_price: item.vat_price)
        OrderItemAddon.add_order_item_addon(orderItem, item)
        # Point.create_point(order, order.user.id, totalAmount[:used_point], "Debit") if is_redeem == "true" && (order.order_type == "postpaid" || (order.order_type == "prepaid" && order.points.debited.blank?))
        offer = item.applied_offer

        if offer.present? && offer.quantity.present? && item.discount_amount.to_f.positive?
          offer.update(quantity: (offer.quantity - item.quantity.to_i))

          if offer.quantity.to_i <= 0
            offer.update(is_active: false, limited_quantity: false, quantity: nil)
            Notification.create(notification_type: "offer_quantity_over", message: "Offer quantity over for Offer No. #{offer.id}", user_id: order.user&.id, receiver_id: order.branch.restaurant.user.id, order_id: order.id, menu_status: "Offer Quantity Over")
          end
        end
      end
    end
  end

  def self.find_items(order_items)
    where(id: order_items)
  end

  def self.find_order_items(order)
    where(order_id: order.id).order(id: "DESC")
  end

  def total_price_per_item
    price_per_item = 0
    total_quantity = 0
    item = menu_item
    offerPercentage = item.offer
    basePrice = item.price_per_item
    quantity = self.quantity
    total_quantity += quantity.to_i
    addOn = 0
    order_item_addons&.each do |addon|
      addonPrice = addon.item_addon.addon_price
      addOn += addonPrice
    end
    pricePerItem = (basePrice + addOn) * total_quantity
    format("%.3f", pricePerItem)
  end

  def price_per_item
    pricePerItem = 0
    item = self
    offerPercentage = item.menu_item.offer
    basePrice = item.menu_item.price_per_item
    addOn = 0
    item.order_item_addons&.each do |addon|
      addonPrice = addon.item_addon.addon_price
      addOn += addonPrice
    end
    pricePerItem = basePrice.to_f + addOn
    format("%.3f", pricePerItem)
   end

  def remove_order
    order&.destroy
  rescue Exception => e
  end
end
