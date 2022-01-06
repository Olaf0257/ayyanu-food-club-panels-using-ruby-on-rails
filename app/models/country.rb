class Country < ApplicationRecord
  COUNTRY_CODES = { 15 => "bh", 87 => "in", 98 => "jo", 101 => "kw", 140 => "om", 151 => "qa", 160 => "sa", 196 => "ae" }.freeze
  PHONE_CODES = { 15 => "973", 87 => "91", 98 => "962", 101 => "965", 140 => "968", 151 => "974", 160 => "966", 196 => "971" }.freeze

  has_many :states, dependent: :destroy
  has_many :event_countries, dependent: :destroy
  has_many :events, through: :event_countries

  validates :name, presence: true, uniqueness: true

  default_scope { order(:name) }

  def as_json(options = {})
    super(options.merge(only: [:id, :name]))
  end
end
