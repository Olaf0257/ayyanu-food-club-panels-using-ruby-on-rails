class CreateRestaurantCouponUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurant_coupon_users do |t|
      t.references :restaurant_coupon, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
