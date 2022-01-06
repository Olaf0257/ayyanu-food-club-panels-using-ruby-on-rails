class UpdateCouponCodeCountries < ActiveRecord::Migration[5.2]
  def up
    InfluencerCoupon.where(country_id: nil).update_all(country_id: 15)
    ReferralCoupon.where(country_id: nil).update_all(country_id: 15)
    RestaurantCoupon.where(country_id: nil).update_all(country_id: 15)
  end

  def down
  end
end
