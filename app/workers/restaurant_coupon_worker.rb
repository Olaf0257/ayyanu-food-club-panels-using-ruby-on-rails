class RestaurantCouponWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(coupon_id, country_id)
    coupon = RestaurantCoupon.find_by(id: coupon_id)

    if coupon.present?
      restaurant_ids = coupon.branches.map(&:restaurant_id).flatten.uniq

      if restaurant_ids.present?
        restaurants = Restaurant.where(id: restaurant_ids)
      elsif country_id.present?
        restaurants = Restaurant.joins(:branches).where(is_signed: true, country_id: country_id, branches: { is_approved: true }).where.not(title: "").distinct
      else
        restaurants = Restaurant.joins(:branches).where(is_signed: true, branches: { is_approved: true }).where.not(title: "").distinct
      end

      restaurants.each do |restaurant|
        UserMailer.send_restaurant_coupon_email(coupon_id, restaurant.id).deliver_now
      end
    end
  end
end