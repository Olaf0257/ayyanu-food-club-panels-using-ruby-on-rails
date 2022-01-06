class Api::V1::OrderReviewsController < Api::ApiController
  before_action :authenticate_guest_access

  def review
    userDetails = @user.presence || user_email(@guestToken + "@foodclube.com")
    order = get_user_last_order(userDetails)
    if order.present? && (order.order_review == false) && (order.review_cancel == false) && (order.is_delivered == true)
      responce_json(code: 200, review: order_review_json(order))
    else
      responce_json(code: 404, message: "No order!!")
    end

    rescue Exception => e
  end

  def order_last_review
    order = get_order_details(params[:order_id])
    if order && (order.is_delivered == true)
      if to_boolean(params[:status]) == "true"
        review = add_order_review(@user, params[:restaurant_id], params[:order_id], params[:packing_rate], params[:value_for_money_rate], params[:delivery_time_rate], params[:quality_of_food_rate])
        order.update(order_review: true)
        responce_json(code: 200, status: true)
      else
        order.update(review_cancel: true)
        responce_json(code: 200, status: true)
      end
    else
      responce_json(code: 404, message: "No order!!")
    end
  end
end
