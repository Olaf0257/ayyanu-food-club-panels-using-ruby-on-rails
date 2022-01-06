class AddColumnToPosPayment < ActiveRecord::Migration[5.2]
  def change
    add_reference :pos_payments, :currency_type, foreign_key: true
  end
end
