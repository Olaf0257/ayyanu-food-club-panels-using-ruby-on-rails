class Api::V1::CartsController < Api::ApiController
  before_action :authenticate_guest_access
  before_action :validate_cart, only: [:add_item_on_cart]
  # after_action :check_discount_amount,only: [:add_item_on_cart]
  def add_item_on_cart
    @item = add_user_cart(@user, @guestToken, params[:branch_id], params[:item_id], params[:item_addons], params[:quantity], params[:description], params[:area_id])
    responce_json(code: 200, message: "Item successfully added.")
  end

  def remove_cart_item
    item = find_cart_item(params[:item_id])
    if item
      item.destroy
      @user.cart.update(branch_id: nil, coverage_area_id: nil) if @user.cart.cart_items.count == 0
      responce_json(code: 200, message: "Item successfully removed.")
    else
      responce_json(code: 422, message: "Invalid item!!")
    end
  end

  def clear_cart
    if @user
      @user.cart.cart_items.destroy_all
    else
      cart = Cart.find_by(guest_token: @guestToken)
      cart&.cart_items&.destroy_all
    end

    responce_json(code: 200, message: "Cart empty.")
    rescue Exception => e
  end

  def view_cart_data
    # begin

    if @user
      cart = @user.cart
      if cart
        sub_total = get_cart_item_total_price(cart, false, request.headers["language"], params[:address_latitude], params[:address_longitude])
        responce_json(code: 200, message: "Cart items", items: cart_list_json(get_cart_item_list(cart, request.headers["language"])), sub_total: sub_total[:sub_total], coverage_area: cart.coverage_area.as_json(language: request.headers["language"]))
      else
        responce_json(code: 200, message: "Cart items", items: [], coverage_area: "")
      end
    else
      p "guestToken"
      cart = Cart.find_by(guest_token: @guestToken)
      if cart
        sub_total = get_cart_item_total_price(cart, false, request.headers["language"], params[:address_latitude], params[:address_longitude])
        responce_json(code: 200, message: "Cart items", items: cart_list_json(get_cart_item_list(cart, request.headers["language"])), sub_total: sub_total[:sub_total], coverage_area: cart.coverage_area.as_json(language: request.headers["language"]))
      else
        responce_json(code: 200, message: "Cart items", items: [], coverage_area: "")
      end
     end
    # rescue Exception => e
    #   responce_json({code: 200, message: "Cart items" ,items: [],:coverage_area=> "" })
    # end
  end

  def cart_item_list
    items = get_cart_menu_item(@user, params[:item_id])
    items.present? ? responce_json(code: 200, message: "Cart items", items: items) : responce_json(code: 422, message: "Invalid item!!")
  end

  def cart_item_total_price
    if @user
      cart = @user.cart

      result = if cart && [true, "true"].include?(params[:checkout_page])
                 get_cart_item_total_price_checkout(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude], false, false)
               elsif cart
                 get_cart_item_total_price(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude])
               else
                 { total_price: 0, total_quantity: 0 }
               end
    else
      cart = Cart.find_by(guest_token: @guestToken)

      result = if cart && [true, "true"].include?(params[:checkout_page])
                 get_cart_item_total_price_checkout(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude], false, false)
               elsif cart
                 get_cart_item_total_price(cart, params[:is_redeem], request.headers["language"], params[:address_latitude], params[:address_longitude])
               else
                 { total_price: 0, total_quantity: 0 }
               end
     end

    responce_json(code: 200, message: "Cart items", data: result)
   end

  def repeat_last
    if @user
      cart = @user.cart
      if cart
        menuItems = cartItemsByItemId(cart, params[:item_id])
        menuItem = menuItems.last
        if menuItem
          menuItem.update(quantity: menuItem.quantity.to_i + 1)
          responce_json(code: 200, message: "Cart items update successfully", item: menuItems)
        else
          responce_json(code: 404, message: "Cart items not found!!")
        end
      else
        responce_json(code: 404, message: "Cart items not found!!")
         end
    else
      cart = Cart.find_by(guest_token: @guestToken)
      if cart
        menuItems = cartItemsByItemId(cart, params[:item_id])
        menuItem = menuItems.last
        if menuItem
          menuItem.update(quantity: menuItem.quantity.to_i + 1)
          responce_json(code: 200, message: "Cart items update successfully", item: menuItems)
        else
          responce_json(code: 404, message: "Cart items not found!!")
        end
      else
        responce_json(code: 404, message: "Cart items not found!!")
      end
        end
   end

  def repeat_last_data_details
    if @user
      cart = @user.cart
      if cart
        menuItems = cartItemsByItemId(cart, params[:item_id])
        menuItems.present? ? responce_json(code: 200, message: "Cart items details", item: menuItems.last) : responce_json(code: 404, message: "Cart items not found!!")
      else
        responce_json(code: 404, message: "Cart items not found!!")
      end
    else
      cart = Cart.find_by(guest_token: @guestToken)
      if cart
        menuItems = cartItemsByItemId(cart, params[:item_id])
        menuItems.present? ? responce_json(code: 200, message: "Cart items details", item: menuItems.last) : responce_json(code: 404, message: "Cart items not found!!")
      else
        responce_json(code: 404, message: "Cart items not found!!")
      end
     end
   end

  def edit_cart_item
    item = find_cart_item(params[:cart_item_id])
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    cart_menu_item = cartItemsByItemId(cart, params[:menu_item_id])
    if (item || cart_menu_item) && (params[:quantity] == "increase")
      item ? item.update(quantity: item.quantity.to_i + 1) : cart_menu_item.first.update(quantity: cart_menu_item.first.quantity.to_i + 1)
      item ? item.as_json : cart_menu_item.as_json
      responce_json(code: 200, quantity: item ? item.quantity : cart_menu_item.first.quantity)
    else
      begin
        if item ? item.quantity.to_i > 1 : cart_menu_item.first.quantity.to_i > 1
          item ? item.update(quantity: item.quantity.to_i - 1) : cart_menu_item.first.update(quantity: cart_menu_item.first.quantity.to_i - 1)
          item ? item.as_json : cart_menu_item.as_json
          responce_json(code: 200, quantity: item ? item.quantity : cart_menu_item.first.quantity)
        else
          item ? item.destroy : cart_menu_item.first.destroy
          cart.update(branch_id: nil) if cart.cart_items.count == 0
          responce_json(code: 200, message: "Cart items remove")
        end
      rescue Exception => e
        responce_json(code: 404, message: "Cart items not found!!")
      end
    end
  end

  def apply_coupon
    @user = User.find(params[:cart_user_id]) if params[:cart_user_id].present?
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    coupon_code = params[:coupon_code]

    if coupon_code.present?
      valid = validate_coupon_code(coupon_code, cart)

      if valid
        applied_coupon = InfluencerCoupon.find_by(coupon_code: coupon_code)
        referral_coupon = ReferralCoupon.find_by(coupon_code: coupon_code)
        restaurant_coupon = RestaurantCoupon.find_by(coupon_code: coupon_code)

        if referral_coupon
          referral_coupon_user = ReferralCouponUser.find_by(referral_coupon_id: referral_coupon.id, user_id: @user&.id, available: true)
          referral_coupon_discount = referral_coupon_user.referrer ? referral_coupon.referrer_discount : referral_coupon.referred_discount
        end

        if InfluencerCouponUser.find_by(influencer_coupon_id: applied_coupon&.id, user_id: @user&.id).present? || RestaurantCouponUser.find_by(restaurant_coupon_id: restaurant_coupon&.id, user_id: @user&.id).present?
          responce_json(code: 422, message: "Coupon Code Already Used")
        elsif referral_coupon_user.present?
          responce_json(code: 200, message: "Coupon Code Successfully Applied", discount: referral_coupon_discount.to_s)
        elsif applied_coupon.present?
          responce_json(code: 200, message: "Coupon Code Successfully Applied", discount: applied_coupon.discount.to_s)
        elsif restaurant_coupon.present?
          responce_json(code: 200, message: "Coupon Code Successfully Applied", discount: restaurant_coupon.discount.to_s)
        end
      else
        responce_json(code: 422, message: "Invalid Coupon Code")
      end
    else
      responce_json(code: 422, message: "Please Enter Coupon Code")
    end
  end

  private

  def validate_cart
    branch = get_restaurant_branch(params[:branch_id])
    item = get_branch_menu_item(branch, params[:item_id]) if branch
    unless branch && item && params[:quantity].present?
      responce_json(code: 422, message: (branch ? item ? "Required parameter messing!!" : "Invalid menu item!!" : "Invalid branch!!").to_s)
     end
    end
end
