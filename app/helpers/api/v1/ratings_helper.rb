module Api::V1::RatingsHelper
  def add_rating(user, rating, description, order_id, branch_id, food_quantity_rating, food_taste_rating, value_rating, packaging_rating, seal_rating, delivery_time_rating, clean_uniform_rating, polite_rating, distance_rating, mask_rating, driver_rating, driver_comments)
    Rating.create_rating(user, rating, description, order_id, branch_id, food_quantity_rating, food_taste_rating, value_rating, packaging_rating, seal_rating, delivery_time_rating, clean_uniform_rating, polite_rating, distance_rating, mask_rating, driver_rating, driver_comments)
  end

  def find_order_rating(order_id)
    Rating.get_order_rating(order_id)
  end
end
