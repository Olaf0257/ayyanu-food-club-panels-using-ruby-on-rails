class CartItem < ApplicationRecord
  belongs_to :menu_item
  belongs_to :cart
  has_many :cart_item_addons, dependent: :destroy
  has_many :item_addons, through: :cart_item_addons

  delegate :item_image, to: :menu_item

  def as_json(options = {})
    @language = options[:language]

    self.item_addons.each do |addon|
      addon.language = @language
    end

    super(options.merge(except: [:created_at, :updated_at, :menu_item_id, :cart_id], methods: [:item_name, :item_image, :item_price, :discount, :after_discount_amount, :total_price, :price_per_item, :item_description, :currency_code_en, :currency_code_ar, :restricted_quantity], include: [item_addons: { only: [:id, :addon_title] }]))
  end

  def currency_code_en
    menu_item.menu_category.branch.restaurant.country.currency_code.to_s
  end

  def currency_code_ar
    menu_item.menu_category.branch.restaurant.country.currency_code.to_s
  end

  def item_name
    if @language == "arabic"
      menu_item.item_name_ar
    else
      menu_item.item_name
    end
  end

  def item_price
    menu_item.price_per_item
  end

  def item_description
    if @language == "arabic"
      menu_item.item_description_ar
    else
      menu_item.item_description
    end
  end

  def applied_offer
    Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", menu_item_id, menu_item.menu_category.branch_id, "all").last
  end

  def restricted_quantity
    applied_offer&.quantity.to_i.positive?
  end

  def discount
    branch = menu_item.menu_category.branch
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", menu_item_id, branch.id, "all").last
    offer.present? ? offer.offer_type == "all" ? offer.discount_percentage.to_i : offer.discount_percentage.to_i : 0
  end

  def after_discount_amount
    branch = menu_item.menu_category.branch
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", menu_item_id, branch.id, "all").last

    if offer
      discountAmount = (price_per_item.to_f * offer.discount_percentage.to_i) / 100
      amount = offer.offer_type == "all" ? format("%0.03f", price_per_item.to_f - discountAmount).to_f : format("%0.03f", price_per_item.to_f - discountAmount)
    else
      format("%.3f", 0)
    end
  end

  def total_price
    total_price = 0
    total_quantity = 0
    sub_total = 0
    offerPrice = 0
    item = menu_item
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", item.id, item.menu_category.branch.id, "all")
    basePrice = item.price_per_item
    quantity = self.quantity
    total_quantity += quantity.to_i
    addOn = 0
    cart_item_addons&.each do |addon|
      addonPrice = addon.item_addon.addon_price
      addOn += addonPrice
    end
    total = total_price + (basePrice.to_f * quantity.to_i) + (quantity.to_i * addOn)
    offerPrice = offer.present? ? (total * offer.last.discount_percentage.to_i) / 100 : 0
    total_price = total - offerPrice
    tax = cart.branch.total_tax_percentage
    total_tax = ((total_price * tax) / 100)
    update(total_item_price: format("%.3f", total_price), vat_price: format("%.3f", total_tax))
    format("%.3f", total_price)
  end

  def price_per_item
    price_per_item = 0
    total_quantity = 0
    item = menu_item
    offerPercentage = item.offer
    basePrice = item.price_per_item
    quantity = self.quantity
    total_quantity += quantity.to_i
    addOn = 0
    cart_item_addons&.each do |addon|
      addonPrice = addon.item_addon.addon_price
      addOn += addonPrice
    end
    price_per_item = basePrice + addOn
    format("%.3f", price_per_item)
  end

  def self.create_cart_item(cart, _branch_id, item_id, item_addons, quantity, description)
    matched_item = ""
    menu_item = MenuItem.find(item_id)
    cart_items = cart.cart_items ? cart.cart_items.where(menu_item_id: item_id).select { |i| i.restricted_quantity == false } : []

    cart_items.each do |item|
      dbCartItemAddon = item.cart_item_addons.pluck(:item_addon_id)
      newAddon = item_addons ? item_addons : []
      common = item_addons.present? ? newAddon.map(&:to_s) - dbCartItemAddon.map(&:to_s) : dbCartItemAddon
      matched_item = item if common.empty? && item.description.blank?
    end

    if matched_item.present? && matched_item.description.blank? && description.blank?
      matched_item.update(quantity: matched_item.quantity.to_i + quantity.to_i)
      matched_item
    elsif !menu_item.restricted_quantity || (menu_item.restricted_quantity && !cart.cart_items.pluck(:menu_item_id).include?(item_id.to_i))
      cartItem = create(menu_item_id: item_id, cart_id: cart.id, quantity: quantity, description: description)
      CartItemAddon.create_cart_item_addons(cartItem, item_addons)
      cartItem
    end
  end

  def self.cart_item(item_id)
    find_by(id: item_id)
  end

  def self.find_cart_menu_item(cart, item_id)
    cart.cart_items.where(menu_item_id: item_id)
  end

  def self.update_item(cartItem, item_id, quantity)
    item = cartItem.update(menu_item_id: item_id, quantity: quantity)
    item ? { code: 200, result: item } : { code: 400, result: item.errors.full_messages.join(", ") }
  end
end
