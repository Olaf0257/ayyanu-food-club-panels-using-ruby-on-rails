class AddRefencesToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_reference :pos_checks, :address
    add_reference :pos_checks, :user
  end
end
