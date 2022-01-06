class AddNotesFieldInCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :influencer_coupons, :notes, :text
    add_column :referral_coupons, :notes, :text
    add_column :restaurant_coupons, :notes, :text
  end
end
