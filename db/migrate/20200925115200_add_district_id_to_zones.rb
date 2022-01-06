class AddDistrictIdToZones < ActiveRecord::Migration[5.2]
  def change
    add_reference :zones, :district, foreign_key: true, index: true
  end
end
