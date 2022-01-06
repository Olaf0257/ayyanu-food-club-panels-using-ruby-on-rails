class UpdateExistingInfluencerCouponQuantities < ActiveRecord::Migration[5.2]
  def up
    InfluencerCoupon.all.each do |coupon|
      coupon.update(total_quantity: coupon.quantity)
    end
  end

  def down
  end
end
