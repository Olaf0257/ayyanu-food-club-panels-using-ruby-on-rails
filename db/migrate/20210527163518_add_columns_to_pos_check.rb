class AddColumnsToPosCheck < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_checks, :is_new_merged, :boolean, default: false
    add_column :pos_checks, :parent_check_id, :integer
    add_reference :pos_checks, :branch
  end
end
