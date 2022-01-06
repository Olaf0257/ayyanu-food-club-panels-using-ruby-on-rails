class AddNoOfGuestInPosTable < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_tables, :no_of_guest, :float
  end
end
