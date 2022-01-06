class AddCountryToCoupons < ActiveRecord::Migration[5.2]
  def change
    add_reference :influencer_coupons, :country, foreign_key: true, index: true
    add_reference :referral_coupons, :country, foreign_key: true, index: true
    add_reference :restaurant_coupons, :country, foreign_key: true, index: true
  end
end
