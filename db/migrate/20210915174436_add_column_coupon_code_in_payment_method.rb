class AddColumnCouponCodeInPaymentMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_payments, :coupon_code, :string
  end
end
