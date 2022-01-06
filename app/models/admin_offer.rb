class AdminOffer < ApplicationRecord
  belongs_to :country
  has_many :offers, dependent: :destroy

  validates :offer_title, :country_id, :limit, presence: true

  scope :search_by_title, ->(title) { where("offer_title LIKE ?", "%#{title}%") }
  scope :search_by_country, ->(country_id) { where(country_id: country_id) }

  def self.admin_offer_list_csv
    CSV.generate do |csv|
      header = "Admin Offer List"
      csv << [header]

      second_row = ["Id", "Title", "Discount(%)", "Country", "Business Offers"]
      csv << second_row

      all.order("created_at DESC").each do |offer|
        @row = []
        @row << offer.id
        @row << offer.offer_title
        @row << offer.offer_percentage
        @row << offer.country.name
        @row << offer.offers.size
        csv << @row
      end
    end
  end
end
