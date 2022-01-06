class RemoveCountryFromUnits < ActiveRecord::Migration[5.2]
  def change
    remove_reference :units, :country, foreign_key: true
    add_column :units, :country_ids, :text
  end
end
