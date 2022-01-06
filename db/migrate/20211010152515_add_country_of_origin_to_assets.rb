class AddCountryOfOriginToAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :assets, :country_of_origin, :string
    add_column :assets, :station_id, :integer
    add_column :assets, :hs_code, :string
    add_column :assets, :item_description, :text
  end
end
