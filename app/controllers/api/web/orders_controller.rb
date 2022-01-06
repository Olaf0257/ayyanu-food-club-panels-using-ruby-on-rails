class Api::Web::OrdersController < Api::ApiController
  before_action :authenticate_guest_access, except: [:cart_details]
  before_action :validate_order, only: [:web_new_order]

  def web_new_order
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    carItems = cart.cart_items

    if carItems.present?

      if (params[:order_mode] == "prepaid") && params[:transaction_id].blank?
        paytabs = create_paytab_payment_page(cart, @user, @guestToken, params[:address_id])
      else
        verifyPayment = verify_web_payment(@user, @guestToken, params[:transaction_id], params[:address_id], params[:pt_transaction_id], params[:pt_token], params[:pt_token_customer_password], params[:pt_token_customer_email], params[:order_mode], params[:note], params[:is_redeem])
        clearCart = clear_cart_deta(cart)
        p "========================verifyPayment============================"
        if verifyPayment
          if @user
            orderPushNotificationWorker(@user, verifyPayment.branch.restaurant.user, "order_created", "Order Created", "Order Id #{verifyPayment.id} is placed by user #{@user.name}", verifyPayment.id)
            orderPusherNotification(@user, verifyPayment)
            responce_json(code: 200, message: "Order placed successfully.", order: order_list_json(verifyPayment, "", ""))
          else
            responce_json(code: 200, message: "Order placed successfully.", order: order_list_json(verifyPayment, "", ""))
          end
        else
          responce_json(code: 422, message: "Invalid transaction!!")
        end
      end
    else
      responce_json(code: 422, message: "Cart empty!!")
    end

    rescue Exception => e
  end

  def cart_details
    url = URI.parse(ENV["PAYTABS_VERIFY_PAYMENT_URL"])
    data = {
      merchant_email: ENV["PAYTABS_EMAIL_ID"],
      secret_key: ENV["PAYTABS_SECRET_KEY"],
      paypage_id: params[:payment_reference],
      reference_number: params[:payment_reference]
    }
    x = Net::HTTP.post_form(url, data)
    render json: eval(x.body)
    # responce_json({code: 200, message: "transaction!!",data: params.inspect})
  end

  private

  def validate_order
    cart = @user.present? ? @user.cart : Cart.find_by(guest_token: @guestToken)
    orderMode = params[:order_mode] == "postpaid" ? get_restaurant_branch(cart.branch_id) : nil
    if (params[:order_mode] == "postpaid") && (orderMode.cash_on_delivery == false)
      responce_json(code: 422, message: "Invalid")
     end
    end
end
