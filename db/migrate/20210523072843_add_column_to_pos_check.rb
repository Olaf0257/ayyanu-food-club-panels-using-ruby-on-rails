class AddColumnToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :check_status, :integer, default: 0
  end
end
