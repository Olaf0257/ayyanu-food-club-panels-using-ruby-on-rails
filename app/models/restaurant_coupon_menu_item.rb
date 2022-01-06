class RestaurantCouponMenuItem < ApplicationRecord
  belongs_to :restaurant_coupon
  belongs_to :menu_item
end
