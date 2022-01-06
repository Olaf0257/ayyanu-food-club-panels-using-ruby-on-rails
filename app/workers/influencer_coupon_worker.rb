class InfluencerCouponWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(coupon_id)
    UserMailer.send_influencer_coupon_email(coupon_id).deliver_now
  end
end