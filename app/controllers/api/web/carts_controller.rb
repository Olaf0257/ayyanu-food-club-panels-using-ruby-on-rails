class Api::Web::CartsController < Api::ApiController
  before_action :authenticate_guest_access

  def web_cart_data_list
    if @user
      cart = @user.cart
      if cart
        # sub_total = get_web_cart_item_total_price(cart) This was old, bug was there
        # This is updated one as working in mobile
        sub_total = get_cart_item_total_price(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude])
        cart_items_count = cart.present? ? cart.cart_items.present? ? cart.cart_items.pluck(:quantity).map(&:to_i).sum : 0 : 0
        responce_json(code: 200, message: "Cart items", items: get_cart_item_list(cart, request.headers["language"]), sub_total: sub_total[:sub_total], total_price: sub_total[:total_price], min_order_amount: sub_total[:min_order_amount], total_point: sub_total[:total_point], tax_percentage: sub_total[:tax_percentage], delivery_charges: sub_total[:delivery_charges], cart_items_count: cart_items_count, coverage_area: cart.branch.coverage_areas.first, branch: cart.branch)
      else
        responce_json(code: 200, message: "Cart items", items: [], coverage_area: "")
      end
    else
      cart = Cart.find_by(guest_token: @guestToken)
      if cart
        # sub_total = get_web_cart_item_total_price(cart)
        sub_total = get_cart_item_total_price(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude])
        cart_items_count = cart.present? ? cart.cart_items.present? ? cart.cart_items.pluck(:quantity).map(&:to_i).sum : 0 : 0
        responce_json(code: 200, message: "Cart items", items: get_cart_item_list(cart, request.headers["language"]), sub_total: sub_total[:sub_total], total_price: sub_total[:total_price], min_order_amount: sub_total[:min_order_amount], total_point: sub_total[:total_point], tax_percentage: sub_total[:tax_percentage], delivery_charges: sub_total[:delivery_charges], cart_items_count: cart_items_count, coverage_area: cart.branch.coverage_areas.first, branch: cart.branch)
      else
        responce_json(code: 200, message: "Cart items", items: [], coverage_area: "")
      end
    end

    rescue Exception => e
  end

  def remove_cart_item
    cart = Cart.find_by(guest_token: @guestToken)
    if cart
      cart_item = cart.cart_items.find_by(id: params[:cart_item_id])
      if cart_item
        cart_item.destroy
        cart.update(branch_id: nil) if cart.cart_items.blank?
        responce_json(code: 200, message: "Cart items remove.")
      else
        responce_json(code: 404, message: "Cart items not present.")
      end
    else
      responce_json(code: 404, message: "Cart items not present.")
    end
  end

  def add_item_special_request
    cart = @user.present? ? @user.cart.presence || Cart.find_by(guest_token: @guestToken) : Cart.find_by(guest_token: @guestToken)
    if cart && params[:cart_item_id] && params[:special_request]
      cart_item = cart.cart_items.find_by(id: params[:cart_item_id])
      if cart_item
        cart_item.update(description: params[:special_request])
        responce_json(code: 200, message: "Special request add successfully.", item: cart_item)
      else
        responce_json(code: 404, message: "Cart items not present.")
      end
    else
      responce_json(code: 404, message: "Cart items not present.")
    end
  end
end
