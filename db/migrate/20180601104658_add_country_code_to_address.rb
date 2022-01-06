class AddCountryCodeToAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :country_code, :string
  end
end
