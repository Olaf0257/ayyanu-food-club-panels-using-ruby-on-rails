class CreateReferralCouponMenuItems < ActiveRecord::Migration[5.2]
  def change
    create_table :referral_coupon_menu_items do |t|
      t.references :referral_coupon, null: false, foreign_key: true, index: true
      t.references :menu_item, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
