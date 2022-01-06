class UpdateCountryList < ActiveRecord::Migration[5.2]
  def up
    ["Congo", "Cruise Ship", "Reunion", "Satellite", "Macedonia"].each do |c|
      Country.find_by(name: c).destroy
    end

    ["Canada", "Central African Republic", "Comoros", "Democratic Republic of the Congo", "Republic of the Congo", "East Timor", "Eritrea", "Eswatini", "Kiribati", "North Korea", "Kosovo", "Malawi", "Marshall Islands", "Federated States of Micronesia", "Myanmar", "Nauru", "North Macedonia", "Palau", "Saint Vincent and the Grenadines", "Sao Tome and Principe", "Solomon Islands", "Somalia", "South Sudan", "Tuvalu", "United States", "Uruguay", "Vanuatu", "Vatican City"].each do |c|
      Country.create(name: c)
    end
  end

  def down
  end
end
