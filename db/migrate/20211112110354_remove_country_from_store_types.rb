class RemoveCountryFromStoreTypes < ActiveRecord::Migration[5.2]
  def change
    remove_reference :store_types, :country, foreign_key: true
    add_column :store_types, :country_ids, :text
  end
end
