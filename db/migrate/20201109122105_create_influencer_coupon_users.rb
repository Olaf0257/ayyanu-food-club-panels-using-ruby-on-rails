class CreateInfluencerCouponUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :influencer_coupon_users do |t|
      t.references :influencer_coupon, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
