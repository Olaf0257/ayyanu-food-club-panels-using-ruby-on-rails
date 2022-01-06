class ReferralCouponBranch < ApplicationRecord
  belongs_to :referral_coupon
  belongs_to :branch
end
