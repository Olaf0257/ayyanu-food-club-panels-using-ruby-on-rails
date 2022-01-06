class AddReferralCouponRole < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Referral Coupons")
  end

  def down
    Privilege.find_by(privilege_name: "Referral Coupons")&.destroy
  end
end
