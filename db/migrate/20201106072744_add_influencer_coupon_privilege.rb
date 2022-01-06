class AddInfluencerCouponPrivilege < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Influencer Coupons")
  end

  def down
    Privilege.find_by(privilege_name: "Influencer Coupons")&.destroy
  end
end
