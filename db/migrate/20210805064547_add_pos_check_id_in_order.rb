class AddPosCheckIdInOrder < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :pos_check, foreign_key: true
  end
end
