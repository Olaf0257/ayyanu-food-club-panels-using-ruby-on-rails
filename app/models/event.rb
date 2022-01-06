class Event < ApplicationRecord
  has_many :event_dates, dependent: :destroy
  has_many :event_countries, dependent: :destroy
  has_many :countries, through: :event_countries

  validates :title, presence: true, uniqueness: { case_sensitive: false }

  accepts_nested_attributes_for :countries

  def self.event_list_csv(country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All Countries"

    CSV.generate do |csv|
      header = "Event List for " + country_name
      csv << [header]

      second_row = ["Title", "Description", "Countries", "Dates"]
      csv << second_row

      all.each do |event|
        @row = []
        @row << event.title
        @row << event.description
        @row << event.reload.countries.pluck(:name).sort.join(" | ")
        @row << (event.reload.event_dates.order(:start_date).map { |date| date.start_date.strftime("%d/%m/%Y").to_s + "#{date.end_date ? '-' : ''}" + date.end_date&.strftime("%d/%m/%Y").to_s }.join(", "))
        csv << @row
      end
    end
  end
end
