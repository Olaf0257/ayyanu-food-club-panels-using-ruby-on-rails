class Api::V1::RatingsController < Api::ApiController
  before_action :authenticate_api_access

  def rating
    order = find_order_id(params[:order_id])
    rating = find_order_rating(params[:order_id])

    if (order.is_delivered == true) && !rating
      rating = add_rating(@user, params[:rating], params[:description], params[:order_id], params[:branch_id], params[:food_quantity_rating].to_s, params[:food_taste_rating].to_s, params[:value_rating].to_s, params[:packaging_rating].to_s, params[:seal_rating].to_s, params[:delivery_time_rating].to_s, params[:clean_uniform_rating].to_s, params[:polite_rating].to_s, params[:distance_rating].to_s, params[:mask_rating].to_s, params[:driver_rating].to_s, params[:driver_comments].to_s)
      responce_json(code: 200, rating: rating[:result])
    else
      responce_json(code: 422, message: "Invalid order")
    end
  end
end
