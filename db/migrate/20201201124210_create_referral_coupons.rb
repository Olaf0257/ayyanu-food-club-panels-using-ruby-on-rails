class CreateReferralCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :referral_coupons do |t|
      t.string :coupon_code, null: false
      t.float :referrer_discount, null: false
      t.float :referred_discount, null: false
      t.integer :total_referrer_quantity, null: false
      t.integer :total_referred_quantity, null: false
      t.integer :referrer_quantity, null: false
      t.integer :referred_quantity, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
