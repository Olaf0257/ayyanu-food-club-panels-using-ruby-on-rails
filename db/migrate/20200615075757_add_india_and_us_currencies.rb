class AddIndiaAndUsCurrencies < ActiveRecord::Migration[5.2]
  def up
    Country.find_by(name: "India")&.update(currency_code: "INR")
    Country.find_by(name: "United States")&.update(currency_code: "USD")
  end

  def down
  end
end
