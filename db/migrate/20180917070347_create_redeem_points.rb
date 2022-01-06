class CreateRedeemPoints < ActiveRecord::Migration[5.1]
  def change
    create_table :redeem_points do |t|
      t.references :order, foreign_key: true
      t.float :point
      t.float :remaining_point

      t.timestamps
    end
  end
end
