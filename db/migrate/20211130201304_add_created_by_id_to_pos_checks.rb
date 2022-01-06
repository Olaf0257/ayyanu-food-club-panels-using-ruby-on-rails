class AddCreatedByIdToPosChecks < ActiveRecord::Migration[5.2]
  def change
    add_column :pos_tables, :created_by_id, :integer
  end
end
