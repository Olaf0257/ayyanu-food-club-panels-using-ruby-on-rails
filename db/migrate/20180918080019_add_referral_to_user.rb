class AddReferralToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :referral, :string
  end
end
