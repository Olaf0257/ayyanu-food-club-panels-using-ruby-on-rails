class AddColumnDriverIdInPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :driver_id, :integer
    add_column :pos_unsaved_checks, :driver_id, :integer
  end
end
