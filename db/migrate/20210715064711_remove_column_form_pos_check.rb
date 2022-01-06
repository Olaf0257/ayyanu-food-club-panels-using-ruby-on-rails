class RemoveColumnFormPosCheck < ActiveRecord::Migration[5.2]
  def change
    remove_column :pos_checks, :check_type, :integer
    remove_column :pos_unsaved_checks, :check_type, :integer
  end
end
