class AddCountryCodeToCountriesTable < ActiveRecord::Migration[5.1]
  def change
    add_column :countries, :currency_code, :string
  end
end
