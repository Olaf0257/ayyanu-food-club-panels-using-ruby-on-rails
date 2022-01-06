class MenuItem < ApplicationRecord
  include Imagescaler

  belongs_to :menu_category

  has_many :cart_items, dependent: :destroy
  has_many :item_addons, through: :item_addon_categories
  has_many :offer, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :menu_item_dates, dependent: :destroy
  has_many :menu_item_addon_categories, dependent: :destroy
  has_many :item_addon_categories, through: :menu_item_addon_categories, source: :item_addon_category
  has_many :influencer_coupon_menu_items, dependent: :destroy
  has_many :influencer_coupons, through: :influencer_coupon_menu_items
  has_many :referral_coupon_menu_items, dependent: :destroy
  has_many :referral_coupons, through: :referral_coupon_menu_items
  has_many :restaurant_coupon_menu_items, dependent: :destroy
  has_many :restaurant_coupons, through: :restaurant_coupon_menu_items
  has_many :pos_transactions, as: :itemable , dependent: :destroy
  serialize :menu_item_ids, Array
  serialize :recipe_ids, Array
  serialize :station_ids, Array

  before_save :downcase_menu_item_stuff

  scope :search_by_name, ->(name) { where("item_name like ?", "%#{ name }%") }
  scope :available, -> { where(is_available: true) }
  scope :unavailable, -> { where(is_available: false) }

  def as_json(options = {})
    @imgWidth = options[:imgWidth]
    @logdinUser = options[:logdinUser]
    @guestToken = options[:guestToken]
    @language = options[:language]
    @branch = options[:branch]

    super(options.merge(except: [:created_at, :hs_id, :updated_at, :menu_category_id, :item_name, :item_description, :item_name_ar, :item_description_ar], methods: [:after_discount_amount, :delivery_time, :discount, :has_addons, :image_thumb, :cart_item_quantity, :item_name, :item_description, :currency_code_en, :currency_code_ar, :restricted_quantity]))
  end

  def recipes
    Recipe.where(id: self.recipe_ids)
  end

  def stations
    Station.where(id: self.station_ids)
  end

  def currency_code_en
    menu_category.branch.restaurant.country.currency_code.to_s
  end

  def currency_code_ar
    menu_category.branch.restaurant.country.currency_code.to_s
  end

  def restricted_quantity
    Offer.active.running.where("(menu_item_id = ?) or (branch_id = ? and offer_type = ?)", id, menu_category.branch_id, "all").last&.quantity.to_i.positive?
  end

  def discount
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", id, @branch.id, "all").last if @branch.present?
    offer.present? ? offer.offer_type == "all" ? offer.discount_percentage.to_i : offer.discount_percentage.to_i : 0
  end

  def after_discount_amount
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", id, @branch.id, "all").last if @branch.present?
    if offer
      discountAmount = (price_per_item.to_f * offer.discount_percentage.to_i) / 100
      amount = offer.offer_type == "all" ? format("%0.03f", price_per_item.to_f - discountAmount).to_f : format("%0.03f", price_per_item.to_f - discountAmount)
    else
      amount = 0
    end
  end

  def effective_price(branch_id)
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", id, branch_id, "all").last if branch_id.present?

    if offer
      discountAmount = (price_per_item.to_f * offer.discount_percentage.to_i) / 100
      price = offer.offer_type == "all" ? format("%0.03f", price_per_item.to_f - discountAmount).to_f : format("%0.03f", price_per_item.to_f - discountAmount)
    else
      price = price_per_item
    end
  end

  def offer_percent(branch_id)
    offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", id, branch_id, "all").last if branch_id.present?
    discount = offer ? offer.discount_percentage.to_i : 0
  end

  def item_name
    if @language == "arabic"
      self["item_name_ar"]
    else
      self["item_name"]
    end
  end

  def item_description
    if @language == "arabic"
      self["item_description_ar"]
    else
      self["item_description"]
    end
  end

  def delivery_time
    delivery_time = menu_category.branch["delivery_time"].to_i
  end

  def has_addons
    item_addon_categories.present?
  end

  def self.find_menu_item(item_id)
    find_by(id: item_id)
  end

  def self.find_menu_item_name(item_name)
    find_by(item_name: item_name)
  end

  def self.find_menu_item_name_catId(item_name, menu_category_id)
    find_by(item_name: item_name, menu_category_id: menu_category_id)
  end

  def self.find_menu_id_catId(menu_item_id, menu_category_id)
    find_by(id: menu_item_id, menu_category_id: menu_category_id)
  end

  def image_thumb
    img_thumb(item_image, @imgWidth)
  end

  def self.find_brach_menu_item(branch, item_id)
    branch.menu_items.find_by(id: item_id)
  end

  def cart_item_quantity
    begin
      cart = @logdinUser ? @logdinUser.cart : Cart.find_by(guest_token: @guestToken)
      itemQuantity = CartItem.where("menu_item_id = ? AND cart_id = ?", id, cart&.id).pluck(:quantity)
      quantity = itemQuantity.map(&:to_i).inject(:+)
      sum = quantity ? quantity : 0
    rescue Exception => e
      itemQuantity = 0
    end
  end

  def self.newMenuItem(item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, calorie, approve, addon_category_id, item_date, far_menu, include_in_pos = true, include_in_app = true, preparation_time = 15, recipe_ids, station_ids)
    menu_item = create(item_name: item_name, price_per_item: price_per_item, item_image: image, item_description: item_description, menu_category_id: menu_category_id, is_available: is_available, item_name_ar: item_name_ar, item_description_ar: item_description_ar, calorie: calorie, approve: approve, far_menu: far_menu, include_in_pos: include_in_pos, include_in_app: include_in_app, preparation_time: preparation_time, recipe_ids: recipe_ids, station_ids: station_ids)

    if menu_item
      if addon_category_id.present?
        addon_category_id.each do |category_id|
          MenuItemAddonCategory.create!(menu_item_id: menu_item.id, item_addon_category_id: category_id.to_i)
        end
      end

      if item_date.present?
        dish_date = item_date.to_s.delete!('"')[1..-2].split(",").collect { |car| car.strip.tr("'", "") }
        menu_item.delete_menu_item_dish_date(dish_date)

        dish_date.each do |date|
          menu_item.menu_item_dates.find_or_create_by(menu_date: date.to_date)
        end
      end
    end
  end

  def delete_menu_item_dish_date(dish_date)
    if dish_date.present?
      menu_item_dates.where("DATE(menu_date) >= (?)", Date.today).find_each do |date|
        unless dish_date.include? date.menu_date.strftime("%Y-%m-%d")
          date.destroy
        end
      end
      # dish_date
    else
      menu_item_dates.destroy_all
    end
  end

  def self.updateMenuItem(item, item_name, price_per_item, image, item_description, menu_category_id, is_available, item_name_ar, item_description_ar, approve, calorie, far_menu, menu_item_ids, recipe_ids, station_ids)
    item.update!(item_name: item_name, price_per_item: price_per_item, item_image: image, item_description: item_description, menu_category_id: menu_category_id, is_available: is_available, item_name_ar: item_name_ar, item_description_ar: item_description_ar, approve: approve, calorie: calorie, is_rejected: false, far_menu: far_menu, menu_item_ids: menu_item_ids, recipe_ids: recipe_ids, station_ids: station_ids)
  end

  def fill_changed_fields(column_names)
    update(changed_column_name: column_names.reject { |i| i == "updated_at" }.join(", ")) if column_names.present?
  end

  private

  def downcase_menu_item_stuff
    self.item_name = item_name.downcase.titleize
    self.item_description = item_description.capitalize
  end
  end
