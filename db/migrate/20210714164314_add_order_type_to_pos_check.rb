class AddOrderTypeToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_reference :pos_checks, :order_type, foreign_key: true
    add_reference :pos_unsaved_checks, :order_type, foreign_key: true
  end
end
