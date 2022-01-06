class CreateReferralCouponUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :referral_coupon_users do |t|
      t.references :referral_coupon, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.boolean :referrer, null: false, default: false
      t.boolean :available, null: false, default: true

      t.timestamps
    end
  end
end
