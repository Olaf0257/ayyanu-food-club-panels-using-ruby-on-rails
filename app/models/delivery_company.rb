class DeliveryCompany < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :contact_no, presence: true
  validates :address1, presence: true

  belongs_to :country
  belongs_to :state, optional: true

  has_many :users, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :delivery_company_shifts, dependent: :destroy

  has_and_belongs_to_many :zones

  scope :approved, -> { where(approved: true) }
  scope :active, -> { where(active: true) }
  scope :search_by_name, ->(name) { where("delivery_companies.name LIKE ?", "%#{name}%") }
  scope :search_by_country, ->(country_id) { where(country_id: country_id) }
  scope :search_by_state, ->(state_id) { joins(zones: :district).where(districts: { state_id: state_id }).distinct }
  scope :search_by_zone, ->(zone_id) { joins(:zones).where(zones: { id: zone_id }).distinct }

  def full_address
    address = ""
    address += address1 if address1.present?
    address += ", " + address2 if address2.present?
    address += ", " + address3 if address3.present?
    address
  end

  def self.delivery_company_list_csv
    CSV.generate do |csv|
      header = "Delivery Company List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Address", "Country", "States", "Zones", "Joined On", "Approved On"]
      csv << second_row

      all.each do |company|
        @row = []
        @row << company.id
        @row << company.name
        @row << company.email
        @row << company.contact_no
        @row << company.full_address
        @row << company.country&.name
        @row << company.zones.map(&:district).flatten.map(&:state).uniq.map(&:name).join(", ")
        @row << (company.zones.pluck(:name).sort.join(", ").presence || "All")
        @row << company.created_at.strftime("%d/%m/%Y")
        @row << company.approved_at&.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.requested_delivery_company_list_csv
    CSV.generate do |csv|
      header = "Requested Delivery Company List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Address", "Country", "States", "Zones", "Requested On"]
      csv << second_row

      all.each do |company|
        @row = []
        @row << company.id
        @row << company.name
        @row << company.email
        @row << company.contact_no
        @row << company.full_address
        @row << company.country&.name
        @row << company.zones.map(&:district).flatten.map(&:state).uniq.map(&:name).join(", ")
        @row << (company.zones.pluck(:name).sort.join(", ").presence || "All")
        @row << company.created_at.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.rejected_delivery_company_list_csv
    CSV.generate do |csv|
      header = "Rejected Delivery Company List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Address", "Country", "States", "Zones", "Reject Reason", "Rejected On"]
      csv << second_row

      all.each do |company|
        @row = []
        @row << company.id
        @row << company.name
        @row << company.email
        @row << company.contact_no
        @row << company.full_address
        @row << company.country&.name
        @row << company.zones.map(&:district).flatten.map(&:state).uniq.map(&:name).join(", ")
        @row << (company.zones.pluck(:name).sort.join(", ").presence || "All")
        @row << company.reject_reason
        @row << company.rejected_at&.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end
end
