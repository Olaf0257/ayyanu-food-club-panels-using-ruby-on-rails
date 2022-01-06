class AddColumnIsDeletedToPosUnsavedTransaction < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_unsaved_transactions, :is_deleted, :boolean, default: false
  end
end
