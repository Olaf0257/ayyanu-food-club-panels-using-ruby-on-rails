class AddUserToRedeemPoint < ActiveRecord::Migration[5.1]
  def change
    add_reference :redeem_points, :user, foreign_key: true
    add_reference :redeem_points, :branch, foreign_key: true
  end
end
