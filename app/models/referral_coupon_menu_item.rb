class ReferralCouponMenuItem < ApplicationRecord
  belongs_to :referral_coupon
  belongs_to :menu_item
end
