class ReferralCouponWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(coupon_id, user_id, referrer)
    UserMailer.send_referral_coupon_email(coupon_id, user_id, referrer).deliver_now
  end
end