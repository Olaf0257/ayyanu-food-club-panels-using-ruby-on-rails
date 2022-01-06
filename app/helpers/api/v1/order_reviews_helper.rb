module Api::V1::OrderReviewsHelper
  def order_review_json(order)
    restaurant = order.branch.restaurant
    transporter = order.transporter
    restaurant_upvote_category = Review.where("review_for = ?", "restaurant").pluck(:review_type)
    transporter_upvote_category = Review.where("review_for = ?", "transporter").pluck(:review_type)
    { order_id: order.id, restaurant: restaurant.as_json(only: [:id, :title, :logo]) }
  end

  def add_order_review(user, restaurant_id, order_id, packing_rating, value_for_money, delivery_time, quality_of_food)
    OrderReview.create_order_review(user, restaurant_id, order_id, packing_rating, value_for_money, delivery_time, quality_of_food)
  end
end
