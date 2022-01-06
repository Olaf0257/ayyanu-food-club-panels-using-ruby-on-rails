module Api::V1::RegistrationsHelper
  def restaurant_category_json(branches, language, area_id)
    branches.as_json(language: language, areaWies: area_id, only: [:id, :min_order_amount, :accept_cash, :accept_card, :delivery_charges])
  end

  def suggest_search_json(branches)
    branches.as_json(only: [:id])
  end

  def search_restaurant_by_category(category_id, area_id, page, per_page)
    Branch.joins(:branch_categories, :branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("restaurants.is_signed = ? and branches.is_closed = (?) and category_id = ? and branch_coverage_areas.coverage_area_id = ? and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.approve = ? and menu_items.approve = ? and menu_categories.available = true and menu_items.is_available = true and branches.is_approved = true", true, false, category_id, area_id, true, true).distinct.order_branches.paginate(page: page, per_page: per_page)
  end

  def update_guest_session_details(user, guestToken)
    if guestToken.present?
      privCart = Cart.where("(user_id = (?) and guest_token != (?)) or (user_id = (?) and guest_token IS NULL)", user.id, guestToken, user.id)
      # guest_token IS NULL or
      p privCart
      privCart.each(&:destroy)
      cart = Cart.find_by(guest_token: guestToken)
      p "============cart==========="
      p cart
      cart&.update(user_id: user.id, branch_id: cart.branch_id)
      p "=====update====="
    end
  end
end
