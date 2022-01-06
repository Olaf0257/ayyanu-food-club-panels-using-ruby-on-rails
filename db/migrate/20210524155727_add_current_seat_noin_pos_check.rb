class AddCurrentSeatNoinPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :current_seat_no, :integer, default: 1
  end
end
