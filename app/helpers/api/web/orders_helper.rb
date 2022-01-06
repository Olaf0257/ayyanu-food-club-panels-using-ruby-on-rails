module Api::Web::OrdersHelper
  def verify_web_payment(user, guestToken, _transaction_id, address_id, _pt_transaction_id, _pt_token, _pt_token_customer_password, _pt_token_customer_email, order_mode, note, is_redeem)
    # url = URI.parse(ENV["PAYTABS_VERIFY_PAYMENT_URL"])
    # data = {:merchant_email => ENV['PAYTABS_EMAIL_ID'],:secret_key => ENV['PAYTABS_SECRET_KEY'],:transaction_id => transaction_id}
    # data_submit = Net::HTTP.post_form(url, data)
    # transactionDetails = JSON.parse(data_submit.body)
    address = Address.find_address(address_id)
    order = order_placed(user, guestToken, "", address, order_mode, note, is_redeem, false, false)
    if order.id.present? && (order_mode == "prepaid")
    end
    rescue Exception => e
  end

  def create_paytab_payment_page(cart, user, _guestToken, address_id)
    address = Address.find_address(address_id)
    amount = get_cart_item_total_price(cart, false, "", params[:address_latitude], params[:address_longitude])
    p amount
    url = URI.parse(ENV["PAYTABS_CREATE_PAYMENT_URL"])
    data = {
      merchant_email: ENV["PAYTABS_EMAIL_ID"],
      secret_key: ENV["PAYTABS_SECRET_KEY"],
      site_url: "http://localhost:3000",
      return_url: "http://localhost:3000/api/web/cart/details",
      title: "Food Club",
      cc_first_name: "test",
      cc_last_name: "test",
      cc_phone_number: "8791905452",
      phone_number: "8791905452",
      email: "test@gmail.com",
      products_per_title: "abc",
      unit_price: 2,
      quantity: 2,
      other_charges: 0,
      amount: 4,
      discount: 0,
      currency: "BHD",
      reference_no: 1,
      ip_customer: "1.1.1.0",
      ip_merchant: "1.1.1.0",
      billing_address: "Flat no 1205 Manama Bahrain",
      city: "Manama",
      state: "Manama",
      postal_code: "00973",
      country: "BHR",
      shipping_first_name: user.name,
      shipping_last_name: user.name,
      address_shipping: "Flat no 1205 Manama Bahrain",
      state_shipping: "Manama",
      city_shipping: "Manama",
      postal_code_shipping: "00973",
      country_shipping: "BHR",
      msg_lang: "english",
      cms_with_version: "ruby on rails 2.4.0"
    }

    x = Net::HTTP.post_form(url, data)
    render json: eval(x.body)
  end

  def full_addresss(address)
    area = address.area.presence || ""
    block = address.block.presence || ""
    street = address.street.presence || ""
    building = address.building.presence || ""
    floor = address.floor.presence || ""
    contact = address.contact.presence || ""
    address_type = address.address_type.presence || ""
    apartment_number = address.apartment_number.presence || ""
    additional_direction = address.additional_direction.presence || ""
    address = area + " " + address_type + " " + block + " " + street + " " + building + " " + floor + " " + apartment_number + " " + additional_direction + "" + contact
    address.strip
  end
end
