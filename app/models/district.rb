class District < ApplicationRecord
  belongs_to :state
  has_many :zones, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: [:state_id] }

  default_scope { order(:name) }

  scope :order_by_date_desc, -> { order("districts.created_at DESC") }
  scope :search_by_name, ->(keyword) { where("districts.name LIKE ?", "%#{keyword}%") }
  scope :search_by_country, ->(country_id) { where(states: { country_id: country_id }) }
  scope :search_by_state, ->(state_id) { where(state_id: state_id) }

  def self.district_list_csv(country_id, state_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    state_name = state_id.present? ? State.find(state_id).name : "All"

    CSV.generate do |csv|
      header = "Districts List"
      csv << [header]
      csv << ["Country: " + country_name, "State: " + state_name]

      second_row = ["Name", "State", "Country"]
      csv << second_row

      all.each do |district|
        @row = []
        @row << district.name
        @row << district.state.name
        @row << district.state.country.name
        csv << @row
      end
    end
  end
end
