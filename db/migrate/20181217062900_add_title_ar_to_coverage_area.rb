class AddTitleArToCoverageArea < ActiveRecord::Migration[5.1]
  def change
    add_column :coverage_areas, :area_ar, :string
  end
end
