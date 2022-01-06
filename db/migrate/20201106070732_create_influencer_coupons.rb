class CreateInfluencerCoupons < ActiveRecord::Migration[5.2]
  def change
    create_table :influencer_coupons do |t|
      t.string :coupon_code, null: false
      t.float :discount, null: false
      t.integer :quantity, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :active, null: false, default: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
