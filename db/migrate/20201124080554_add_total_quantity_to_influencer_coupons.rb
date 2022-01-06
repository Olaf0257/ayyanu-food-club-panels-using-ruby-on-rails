class AddTotalQuantityToInfluencerCoupons < ActiveRecord::Migration[5.2]
  def change
    add_column :influencer_coupons, :total_quantity, :integer, null: false
  end
end
