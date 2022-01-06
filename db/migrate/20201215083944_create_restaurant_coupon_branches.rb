class CreateRestaurantCouponBranches < ActiveRecord::Migration[5.2]
  def change
    create_table :restaurant_coupon_branches do |t|
      t.references :restaurant_coupon, null: false, foreign_key: true, index: true
      t.references :branch, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
