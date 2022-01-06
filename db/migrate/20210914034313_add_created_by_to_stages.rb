class AddCreatedByToStages < ActiveRecord::Migration[5.2]
  def change
    add_column :stages, :created_by_id, :integer
  end
end
