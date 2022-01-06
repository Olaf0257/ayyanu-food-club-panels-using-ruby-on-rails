class Tax < ApplicationRecord
  belongs_to :country

  validates :percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true, uniqueness: { scope: [:country_id], case_sensitive: false }

  def name_with_percentage
    name + " #{percentage}%"
  end

  def self.tax_list_csv(country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All Countries"

    CSV.generate do |csv|
      header = "Tax List for " + country_name
      csv << [header]

      second_row = ["Country", "Tax Name", "Tax Percentage"]
      csv << second_row

      all.each do |tax|
        @row = []
        @row << tax.country.name
        @row << tax.name
        @row << tax.percentage
        csv << @row
      end
    end
  end
end
