class OrderReview < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant
  belongs_to :order

  def self.create_order_review(user, restaurant_id, order_id, packing_rating, value_for_money, delivery_time, quality_of_food)
    create(user_id: user.id, restaurant_id: restaurant_id, order_id: order_id, packing_rate: packing_rating, value_for_money_rate: value_for_money, delivery_time_rate: delivery_time, quality_of_food_rate: quality_of_food)
  end
end
