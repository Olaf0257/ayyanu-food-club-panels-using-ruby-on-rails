class Zone < ApplicationRecord
  belongs_to :district
  has_many :coverage_areas, dependent: :nullify
  has_and_belongs_to_many :delivery_companies
  has_and_belongs_to_many :users

  validates :name, :name_ar, presence: true
  validates :name, :name_ar, uniqueness: { scope: [:district_id] }

  attr_accessor :language

  scope :order_by_date_desc, -> { order(created_at: :desc) }
  scope :search_by_name, ->(keyword) { where("zones.name LIKE ?", "%#{keyword}%") }
  scope :search_by_district, ->(district_id) { where(district_id: district_id) }

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    super(options.merge(only: [:id], methods: [:zone_name]))
  end

  def zone_name
    if @language == "arabic"
      self["name_ar"]
    else
      self["name"]
    end
  end

  def self.zone_list_csv(district_id)
    district_name = district_id.present? ? District.find(district_id).name : "All"

    CSV.generate do |csv|
      header = "Zones List"
      csv << [header]
      csv << ["District: " + district_name]

      second_row = ["Name (English)", "Name (Arabic)", "District"]
      csv << second_row

      all.each do |zone|
        @row = []
        @row << zone.name
        @row << zone.name_ar
        @row << zone.district.name
        csv << @row
      end
    end
  end
end
