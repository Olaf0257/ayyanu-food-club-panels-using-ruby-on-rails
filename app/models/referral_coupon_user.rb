class ReferralCouponUser < ApplicationRecord
  belongs_to :referral_coupon
  belongs_to :user

  def self.list_csv(coupon_code)
    CSV.generate do |csv|
      header = "Coupon Users for " + coupon_code
      csv << [header]

      second_row = ["Sl No", "Name", "Email", "Type", "Used On"]
      csv << second_row

      all.order(id: :desc).each_with_index do |coupon_user, i|
        user = User.find(coupon_user.user_id)
        @row = []
        @row << (i + 1)
        @row << user.name
        @row << user.email
        @row << (coupon_user.referrer ? "Referrer" : "Referred")
        @row << coupon_user.created_at.strftime("%d %b %Y %l:%M %p")
        csv << @row
      end
    end
  end
end
