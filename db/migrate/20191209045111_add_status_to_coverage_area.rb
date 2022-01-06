class AddStatusToCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_column :coverage_areas, :status, :integer ,default: 0, index: true
  end
end
