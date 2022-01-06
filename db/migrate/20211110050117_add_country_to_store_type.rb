class AddCountryToStoreType < ActiveRecord::Migration[5.2]
  def change
    add_reference :store_types, :country, foreign_key: true
    add_column :store_types, :branch_ids, :string
  end
end
