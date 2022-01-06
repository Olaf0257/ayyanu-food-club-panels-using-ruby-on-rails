class AddRestaurantCouponPrivilege < ActiveRecord::Migration[5.2]
  def up
    Privilege.create(privilege_name: "Restaurant Coupons")
  end

  def down
    Privilege.find_by(privilege_name: "Restaurant Coupons")&.destroy
  end
end
