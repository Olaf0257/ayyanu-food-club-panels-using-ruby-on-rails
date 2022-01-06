class Cart < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :branch, optional: true
  belongs_to :coverage_area, optional: true
  has_many :cart_items, dependent: :destroy

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at]))
  end

  def self.create_cart(user, guestToken, branch_id, item_id, item_addons, quantity, description, area_id)
    if user
      cart = user.cart

      if cart
        if cart.branch_id != branch_id.to_i
          cart.cart_items.destroy_all
          cartDetails = cart.update(branch_id: branch_id, coverage_area_id: area_id)
          CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
        else
          cartDetails = cart.update(branch_id: branch_id, coverage_area_id: area_id)
          item = CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
        end
      else
        cart = create(user_id: user.id, branch_id: branch_id, description: branch_id, coverage_area_id: area_id)
        CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
      end
    else
      if guestToken
        cart = Cart.find_by(guest_token: guestToken)

        if cart
          if cart.branch_id != branch_id.to_i
            cart.cart_items.destroy_all
            cartDetails = cart.update(branch_id: branch_id, coverage_area_id: area_id)
            CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
          else
            cartDetails = cart.update(branch_id: branch_id, coverage_area_id: area_id)
            item = CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
          end
        else
          cart = create(guest_token: guestToken, branch_id: branch_id, description: branch_id, coverage_area_id: area_id)
          CartItem.create_cart_item(cart, branch_id, item_id, item_addons, quantity, description)
        end
      end
    end
    rescue Exception => e
  end

  def self.filter_by_query(restaurant_id, area_id, keyword, start_date, end_date)
    carts = all
    carts = carts.where(branches: { restaurant_id: restaurant_id }) if restaurant_id.present?
    carts = carts.where(coverage_area_id: area_id) if area_id.present?
    carts = carts.joins(:user, :branch).where("users.name like ? OR branches.address like ?", "%#{keyword}%", "%#{keyword}%") if keyword.present?
    carts = carts.where("DATE(carts.updated_at) >= ?", start_date.to_date) if start_date.present?
    carts = carts.where("DATE(carts.updated_at) <= ?", end_date.to_date) if end_date.present?
    carts
  end

  def self.list_csv
    CSV.generate do |csv|
      header = "User Carts List"
      csv << [header]

      second_row = ["Country", "User", "Restaurant", "Branch", "Area", "Item Count", "Total Price", "Last Updated"]
      csv << second_row

      all.order(updated_at: :desc).each do |cart|
        @row = []
        @row << (cart.branch&.restaurant&.country&.name.presence || "NA")
        @row << (cart.user&.name.presence || "NA")
        @row << (cart.branch&.restaurant&.title.presence || "NA")
        @row << (cart.branch&.address.presence || "NA")
        @row << (cart.coverage_area&.area.presence || "NA")
        @row << cart.cart_items.size
        @row << ApplicationController.helpers.number_with_precision(cart.cart_items.map(&:total_price).sum.to_f.round(3), precision: 3) + " " + cart.branch&.currency_code_en.to_s
        @row << cart.updated_at.strftime("%d/%m/%Y %l:%M%p")
        csv << @row
      end
    end
  end
end
