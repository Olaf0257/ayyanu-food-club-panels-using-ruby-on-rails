class ReportSubscription < ApplicationRecord
  belongs_to :country

  has_many :branches, dependent: :nullify

  validates :fee, presence: true, uniqueness: { scope: :country_id }

  scope :order_by_fee, -> { order(:country_id, :fee) }
  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }
end
