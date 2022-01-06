class AddcolumnInPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :kds_type, :string, default: 'Station'
    add_column :pos_unsaved_checks, :kds_type, :string, default: 'Station'
  end
end
