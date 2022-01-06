class RemoveCountryIdFromZones < ActiveRecord::Migration[5.2]
  def change
    remove_column :zones, :country_id
  end
end
