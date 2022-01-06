class UpdateCurrencyCodes < ActiveRecord::Migration[5.2]
  def up
    Country.find_by(name: "India")&.update(currency_code: "INR")
    Country.find_by(name: "United States")&.update(currency_code: "USD")
    Country.find_by(name: "Bahrain")&.update(currency_code: "BHD")
    Country.find_by(name: "United Arab Emirates")&.update(currency_code: "AED")
    Country.find_by(name: "Saudi Arabia")&.update(currency_code: "SAR")
    Country.find_by(name: "Jordan")&.update(currency_code: "JOD")
    Country.find_by(name: "Kuwait")&.update(currency_code: "KWD")
    Country.find_by(name: "Oman")&.update(currency_code: "OMR")
    Country.find_by(name: "Qatar")&.update(currency_code: "QAR")
  end

  def down
  end
end
