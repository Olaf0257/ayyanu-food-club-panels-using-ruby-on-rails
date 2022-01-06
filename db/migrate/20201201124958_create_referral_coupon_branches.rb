class CreateReferralCouponBranches < ActiveRecord::Migration[5.2]
  def change
    create_table :referral_coupon_branches do |t|
      t.references :referral_coupon, null: false, foreign_key: true, index: true
      t.references :branch, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
