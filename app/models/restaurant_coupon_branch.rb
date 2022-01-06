class RestaurantCouponBranch < ApplicationRecord
  belongs_to :restaurant_coupon
  belongs_to :branch
end
