module Api::V1::CartsHelper
  def cart_item_json(item)
    item.as_json.merge(title: item.menu_item.item_name, url: item.menu_item.item_image)
  end

  def cart_list_json(items)
    items.as_json
  end

  def item_addon_except_attributes
    { except: [:created_at, :updated_at, :id, :user_id] }
  end

  def add_user_cart(user, _guestToken, branch_id, item_id, item_addons, quantity, description, area_id)
    if user
      cart = user.cart
      Cart.create_cart(user, nil, branch_id, item_id, item_addons, quantity, description, area_id)
    else
      Cart.create_cart(user, @guestToken, branch_id, item_id, item_addons, quantity, description, area_id)
    end
  end

  def get_cart_item(branch_id, item_id)
    branch = get_restaurant_branch(branch_id)
    item = branch.menu_items.find_by(id: item_id)
  end

  def update_cart_item(_user, _branch_id, cart_item_id, item_id, item_addons, quantity)
    cartItem = find_cart_item(cart_item_id)
    updateItem = CartItem.update_item(cartItem, item_id, quantity)
    if updateItem[:code] == 200
      updateaddons = CartItemAddon.update_cart_addons(CartItem, item_addons)
    end
  end

  def find_cart_item(item_id)
    CartItem.cart_item(item_id)
  end

  def get_cart_item_list(cart, language)
    cart.cart_items.as_json(language: language)
  end

  def get_cart_item_total_price_checkout(cart, is_redeem, language, address_latitude, address_longitude, on_demand, dine_in_order)
    total_price = 0
    total_quantity = 0
    sub_total = 0
    items = cart.cart_items
    total_point = 0
    usedPoint = 0
    afterOffer = 0
    branch_latitude = cart.branch.latitude
    branch_longitude = cart.branch.longitude
    @third_party_min_order_amount = nil
    area = BranchCoverageArea.get_branch_coverage_area(cart.coverage_area_id, cart.branch_id)
    totalPoint = cart.user_id.present? ? cart.branch_id.present? ? branch_available_point(cart.user.id, cart.branch.id) : 0.000 : 0.000

    items.each do |item|
      offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", item.menu_item.id, cart.branch_id, "all")
      basePrice = item.menu_item.price_per_item
      quantity = item.quantity
      total_quantity += quantity.to_i
      addOn = 0

      item.cart_item_addons&.each do |addon|
        addonPrice = addon.item_addon.addon_price
        addOn += addonPrice
      end

      sub_total = (basePrice.to_f * quantity.to_i) + (quantity.to_i * addOn)
      offerPrice = offer.present? ? offer.last.offer_type == "all" ? (sub_total * offer.last.discount_percentage.to_i) / 100 : (sub_total * offer.last.discount_percentage.to_i) / 100 : 0.000
      item.update(discount_amount: helpers.number_with_precision(offerPrice, precision: 3).to_f)

      if params[:coupon_code].present?
        coupon = InfluencerCoupon.find_by(coupon_code: params[:coupon_code]) || ReferralCoupon.find_by(coupon_code: params[:coupon_code]) || RestaurantCoupon.find_by(coupon_code: params[:coupon_code])
        @referral_coupon_user = ReferralCouponUser.where(referral_coupon_id: coupon.id, user_id: cart.user_id, available: true).first if coupon.class.name == "ReferralCoupon"

        if coupon.present?
          if coupon.branches.present? && coupon.menu_items.select { |i| i.menu_category.branch_id == cart.branch_id }.present?
            flag = (coupon.menu_items.pluck(:id) & cart.cart_items.pluck(:menu_item_id)).present?
          else
            flag = (cart.branch.restaurant.country_id == coupon.country_id)
          end

          if flag
            if @referral_coupon_user
              coupon_discount = @referral_coupon_user.referrer ? coupon.referrer_discount : coupon.referred_discount
              coupon_price = (sub_total * coupon_discount.to_f) / 100
              @coupon_discount = coupon_discount
            elsif ["InfluencerCoupon", "RestaurantCoupon"].include?(coupon.class.name)
              coupon_price = (sub_total * coupon.discount.to_f) / 100
              @coupon_discount = coupon.discount
            end
          end
        end
      end

      afterOffer += (sub_total - offerPrice)

      if coupon_price.present?
        item.update(discount_amount: helpers.number_with_precision(coupon_price, precision: 3).to_f)
        item.update(total_item_price: (sub_total - item.discount_amount))
        afterOffer -= coupon_price
      end
    end

    tax = cart.branch.total_tax_percentage
    afterOffer = (afterOffer * 100) / (100 + tax).to_f.round(3)

    total_point = if to_boolean(is_redeem) == "true"
                    if totalPoint >= afterOffer
                      totalPoint - afterOffer
                    elsif totalPoint >= 1
                      0
                    else
                      totalPoint
                    end
                  else
                    totalPoint
                  end

    usedPoint = if to_boolean(is_redeem) == "true"
                  if totalPoint >= afterOffer
                    afterOffer
                  elsif totalPoint >= 1
                    totalPoint
                  else
                    0
                  end
                else
                  0
                end

    total_price = if to_boolean(is_redeem) == "true"
                    if totalPoint >= afterOffer
                      0
                    elsif totalPoint >= 1
                      afterOffer - totalPoint
                    else
                      afterOffer
                    end
                  else
                    afterOffer
                  end

    address_latitude ||= cart.coverage_area.latitude
    address_longitude ||= cart.coverage_area.longitude

    if dine_in_order
      delivery_charge = 0.0
    else
      if cart
        if area.present?
          if area.third_party_delivery || on_demand
            if branch_latitude.present? && branch_longitude.present? && address_latitude.present? && address_longitude.present?
              dist = Geocoder::Calculations.distance_between([branch_latitude, branch_longitude], [address_latitude, address_longitude], units: :km).to_f.round(3)
              @third_party_min_order_amount = get_min_order_amount_by_distance(dist, cart.branch&.restaurant&.country_id)

              if on_demand
                delivery_charge = get_delivery_service_by_distance(dist, cart.branch&.restaurant&.country_id)
              elsif area.third_party_delivery_type == "Chargeable"
                delivery_charge = get_delivery_charge_by_distance(dist, cart.branch&.restaurant&.country_id)
              else
                delivery_charge = 0.0
              end
            else
              delivery_charge = 0.0
            end
          else
            delivery_charge = area.delivery_charges.to_f
          end
        else
          delivery_charge = cart.branch.delivery_charges.to_f
        end
      else
        delivery_charge = 0.0
      end
    end

    catering_items = cart.cart_items.any? { |i| i.menu_item.menu_category.category_title == "Catering" }
    accept_card = area.present? ? area.accept_card : cart.branch.accept_card
    accept_cash = catering_items ? false : (area.present? ? area.accept_cash : cart.branch.accept_cash)
    cash_on_delivery = catering_items ? false : (area.present? ? area.cash_on_delivery : cart.branch.cash_on_delivery)
    currency_code = cart.branch.restaurant.country.currency_code.to_s
    totalWithout_tax = total_price + delivery_charge
    base_price = afterOffer
    taxable_amount = base_price - usedPoint
    taxable_amount = (taxable_amount + delivery_charge) if area && !area.third_party_delivery && !on_demand
    total_tax_amount = (taxable_amount * tax / 100.to_f)
    total_after_tax = base_price + total_tax_amount + delivery_charge - usedPoint
    all_taxes = []

    cart.branch.branch_taxes.each do |tax|
      all_taxes << { tax_name: tax.name, tax_percentage: tax.percentage, tax_amount: (taxable_amount * tax.percentage / 100.to_f).to_f.round(3) }
    end

    { total_price: helpers.number_with_precision(total_after_tax, precision: 3).to_f,
      sub_total: helpers.number_with_precision(base_price, precision: 3).to_f,
      total_quantity: total_quantity,
      tax_percentage: tax,
      total_tax_amount: helpers.number_with_precision(total_tax_amount, precision: 3).to_f,
      delivery_charges: delivery_charge.to_s,
      total_point: total_point.to_f.round(3),
      used_point: usedPoint.to_f.round(3),
      restaurant_name: cart.branch ? language == "arabic" ? cart.branch.restaurant.title_ar.presence || cart.branch.restaurant.title : cart.branch.restaurant.title : cart.branch.restaurant.title,
      branch_id: cart ? cart.branch.id : 0,
      address: cart ? language == "arabic" ? cart.branch.address_ar.presence || cart.branch.address : cart.branch.address : cart.branch.address_ar,
      min_order_amount: cart ? area.present? ? (@third_party_min_order_amount.presence || area.minimum_amount) : cart.branch.min_order_amount : 0,
      cash_on_delivery: cash_on_delivery,
      accept_card: accept_card,
      accept_cash: accept_cash,
      is_busy: area.present? ? area.is_busy : "",
      is_closed: area.present? ? area.is_closed : "",
      fc_delivery: area&.third_party_delivery ? true : false,
      currency_code_en: currency_code,
      currency_code_ar: currency_code,
      coupon_discount: @coupon_discount,
      taxes: all_taxes.as_json }
  rescue Exception => e
  end

  def get_cart_item_total_price(cart, is_redeem, language, address_latitude, address_longitude)
    total_price = 0
    total_quantity = 0
    sub_total = 0
    items = cart.cart_items
    total_point = 0
    usedPoint = 0
    afterOffer = 0
    branch_latitude = cart.branch.latitude
    branch_longitude = cart.branch.longitude
    @third_party_min_order_amount = nil
    # Point.where("user_id = ? and branch_id = (?)",cart.user.id,cart.branch.id).pluck(:user_point).sum
    area = BranchCoverageArea.get_branch_coverage_area(cart.coverage_area_id, cart.branch_id)
    totalPoint = cart.user_id.present? ? cart.branch_id.present? ? branch_available_point(cart.user.id, cart.branch.id) : 0.000 : 0.000
    items.each do |item|
      offer = Offer.active.running.where("(menu_item_id = (?)) or (branch_id = (?) and offer_type = ?)", item.menu_item.id, cart.branch_id, "all")
      basePrice = item.menu_item.price_per_item
      quantity = item.quantity
      # ========(1 BHD = 1 point)======
      total_quantity += quantity.to_i
      addOn = 0
      item.cart_item_addons&.each do |addon|
        addonPrice = addon.item_addon.addon_price
        addOn += addonPrice
      end
      sub_total = (basePrice.to_f * quantity.to_i) + (quantity.to_i * addOn)
      offerPrice = offer.present? ? offer.last.offer_type == "all" ? (sub_total * offer.last.discount_percentage.to_i) / 100 : (sub_total * offer.last.discount_percentage.to_i) / 100 : 0.000
      item.update(discount_amount: helpers.number_with_precision(offerPrice, precision: 3).to_f)
      afterOffer += (sub_total - offerPrice)
    end

    total_point = if to_boolean(is_redeem) == "true"
                    if totalPoint >= afterOffer
                      totalPoint - afterOffer
                    elsif totalPoint >= 1
                      0
                    else
                      totalPoint
                    end
                  else
                    totalPoint
                  end

    usedPoint = if to_boolean(is_redeem) == "true"
                  if totalPoint >= afterOffer
                    afterOffer
                  elsif totalPoint >= 1
                    totalPoint
                  else
                    0
                  end
                else
                  0
                end

    total_price = if to_boolean(is_redeem) == "true"
                    if totalPoint >= afterOffer
                      0
                    elsif totalPoint >= 1
                      afterOffer - totalPoint
                    else
                      afterOffer
                    end
                  else
                    afterOffer
                  end

    address_latitude ||= cart.coverage_area.latitude
    address_longitude ||= cart.coverage_area.longitude

    if cart
      if area.present?
        if area.third_party_delivery
          if branch_latitude.present? && branch_longitude.present? && address_latitude.present? && address_longitude.present?
            dist = Geocoder::Calculations.distance_between([branch_latitude, branch_longitude], [address_latitude, address_longitude], units: :km).to_f.round(3)
            @third_party_min_order_amount = get_min_order_amount_by_distance(dist, cart.branch&.restaurant&.country_id)

            if area.third_party_delivery_type == "Chargeable"
              delivery_charge = get_delivery_charge_by_distance(dist, cart.branch&.restaurant&.country_id)
            else
              delivery_charge = 0.0
            end
          else
            delivery_charge = 0.0
          end
        else
          delivery_charge = area.delivery_charges.to_f
        end
      else
        delivery_charge = cart.branch.delivery_charges.to_f
      end
    else
      delivery_charge = 0.0
    end

    catering_items = cart.cart_items.any? { |i| i.menu_item.menu_category.category_title == "Catering" }
    accept_card = area.present? ? area.accept_card : cart.branch.accept_card
    accept_cash = catering_items ? false : (area.present? ? area.accept_cash : cart.branch.accept_cash)
    cash_on_delivery = catering_items ? false : (area.present? ? area.cash_on_delivery : cart.branch.cash_on_delivery)
    currency_code = cart.branch.restaurant.country.currency_code.to_s

    tax = cart.branch.total_tax_percentage
    totalWithout_tax = total_price + delivery_charge
    total_tax_amount = cart.cart_items.pluck(:vat_price).sum
    total_after_tax =  totalWithout_tax
    { total_price: helpers.number_with_precision(total_after_tax, precision: 3).to_f, sub_total: helpers.number_with_precision(afterOffer, precision: 3).to_f, total_quantity: total_quantity, tax_percentage: tax, delivery_charges: delivery_charge.to_s, cash_on_delivery: cash_on_delivery, accept_card: accept_card, accept_cash: accept_cash, restaurant_name: cart.branch ? language == "arabic" ? cart.branch.restaurant.title_ar.presence || cart.branch.restaurant.title : cart.branch.restaurant.title : cart.branch.restaurant.title, branch_id: cart ? cart.branch.id : 0, address: cart ? language == "arabic" ? cart.branch.address_ar.presence || cart.branch.address : cart.branch.address : cart.branch.address_ar, min_order_amount: cart ? area.present? ? (@third_party_min_order_amount.presence || area.minimum_amount) : cart.branch.min_order_amount : 0, total_point: total_point, used_point: usedPoint, is_busy: area.present? ? area.is_busy : "", is_closed: area.present? ? area.is_closed : "", total_tax_amount: helpers.number_with_precision(total_tax_amount, precision: 3).to_f, currency_code_en: currency_code, currency_code_ar: currency_code }
    rescue Exception => e
  end

  def validate_coupon_code(coupon_code, cart)
    coupon = InfluencerCoupon.find_by(coupon_code: coupon_code) || ReferralCoupon.joins(:referral_coupon_users).where(coupon_code: coupon_code, referral_coupon_users: { user_id: cart&.user_id, available: true }).first || RestaurantCoupon.find_by(coupon_code: coupon_code)

    if coupon.present? && cart.present? && (coupon.branches.pluck(:id).include?(cart.branch_id) || coupon.branches.blank?) && coupon.active && (coupon.start_date <= Date.today) && (coupon.end_date >= Date.today)
      if ["InfluencerCoupon", "RestaurantCoupon"].include?(coupon.class.name)
        if coupon.branches.present? && coupon.menu_items.select { |i| i.menu_category.branch_id == cart.branch_id }.present?
          (coupon.menu_items.pluck(:id) & cart.cart_items.pluck(:menu_item_id)).present?
        else
          cart.branch.restaurant.country_id == coupon.country_id
        end
      elsif coupon.class.name == "ReferralCoupon"
        referral_coupon_user = ReferralCouponUser.where(referral_coupon_id: coupon.id, user_id: cart&.user_id, available: true).first
        available = referral_coupon_user.referrer ? referral_coupon_user.referral_coupon.referrer_quantity.positive? : referral_coupon_user.referral_coupon.referred_quantity.positive?

        if available
          if coupon.branches.present? && coupon.menu_items.select { |i| i.menu_category.branch_id == cart.branch_id }.present?
          (coupon.menu_items.pluck(:id) & cart.cart_items.pluck(:menu_item_id)).present?
          else
            cart.branch.restaurant.country_id == coupon.country_id
          end
        end
      end
    else
      false
    end
  end

  def cart_item_counts
    if @user
      cart = @user.cart
      count = if cart
                cart.cart_items.count
              else
                0
              end
    else
      cart = Cart.find_by(guest_token: @guestToken)
      count = if cart
                cart.cart_items.count
              else
                0
              end
    end
  end

  def get_delivery_charge_by_distance(distance, country_id)
    charge = 0

    DistanceDeliveryCharge.where(country_id: country_id).each do |d|
      range = d.min_distance...d.max_distance

      if range.cover?(distance)
        charge = d.charge
        break
      end
    end

    charge
  end

  def get_delivery_service_by_distance(distance, country_id)
    service = 0

    DistanceDeliveryCharge.where(country_id: country_id).each do |d|
      range = d.min_distance...d.max_distance

      if range.cover?(distance)
        service = d.delivery_service
        break
      end
    end

    service
  end

  def get_min_order_amount_by_distance(distance, country_id)
    amount = 0

    DistanceDeliveryCharge.where(country_id: country_id).each do |d|
      range = d.min_distance...d.max_distance

      if range.cover?(distance)
        amount = d.min_order_amount
        break
      end
    end

    amount
  end
end
