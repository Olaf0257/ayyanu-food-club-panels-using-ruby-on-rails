class AddRequestedToCoverageAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :coverage_areas, :requested, :boolean, null: false, default: false
  end
end
