class CoverageArea < ApplicationRecord
  STATUS_TYPES = [["Active Areas", "active"], ["Deactivated Areas", "deactivate"]]

  belongs_to :city, optional: true
  belongs_to :country, optional: true
  belongs_to :zone, optional: true
  has_many :addresses, dependent: :destroy
  has_many :branch_coverage_areas, dependent: :destroy
  has_many :branches, through: :branch_coverage_areas
  has_many :add_requests, dependent: :destroy
  has_many :coverage_area_locations, dependent: :destroy
  has_many :suggest_restaurants, dependent: :destroy
  has_many :new_restaurants, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  before_save :downcase_coverage_area_stuff

  validates :area, uniqueness: { scope: [:country_id], case_sensitive: false }

  scope :active_areas, -> { where(status: "active") }
  scope :dummy_area, -> { where(area: "No Area Present") }
  scope :requested_areas, -> { where(requested: true) }
  scope :non_requested_areas, -> { where(requested: false) }
  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }
  scope :filter_by_zone, ->(zone_id) { where(zone_id: zone_id) }
  scope :order_by_name, -> { order(:area) }

  enum status: [:active, :deactivate]

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    super(options.merge(except: [:created_at, :updated_at, :city_id, :area, :area_ar, :status], methods: [:area]))
  end

  def self.get_all_coverage_area(country_id, keyword)
    areas = active_areas.where("area like (?) and status = (?)", "%#{keyword}%", "active")
    areas = areas.where(country_id: country_id) if country_id
    areas = CoverageArea.dummy_area if areas.blank? && keyword.blank?
    areas.order(:area)
  end

  def self.get_all_coverage_area_for_web(keyword, page, per_page)
    active_areas.where("area LIkE (?)", "%#{keyword}%").order(area: "ASC").paginate(page: page, per_page: per_page)
  end

  def self.get_area(area_id)
    find_by(id: area_id)
  end

  def area
    if @language == "arabic"
      self["area_ar"].presence || self["area"]
    else
      self["area"]
    end
  end

  def self.get_coverage_areas(area_id)
    where(id: area_id)
  end

  def self.search_by_keyword(keyword)
    joins(:city).where(["area LIKE ? or city LIKE ? or state LIKE ?", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%"])
  end

  def self.area_list_csv(country_id, zone_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    zone_name = zone_id.present? ? Zone.find(zone_id).name : "All"

    CSV.generate do |csv|
      header = "Coverage Area List"
      csv << [header]
      csv << ["Country: " + country_name, "Zone: " + zone_name]

      second_row = ["Name(English)", "Name(Arabic)", "City", "Zone", "Country", "Location", "Latitude", "Longitude", "Status"]
      csv << second_row

      all.order_by_name.each do |area|
        @row = []
        @row << area.area
        @row << area.area_ar
        @row << area.city&.city
        @row << area.zone&.name
        @row << area.country&.name
        @row << area.location
        @row << area.latitude
        @row << area.longitude
        @row << area.status.capitalize
        csv << @row
      end
    end
  end

  def self.new_area_list_csv(country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"

    CSV.generate do |csv|
      header = "New Coverage Area List"
      csv << [header]
      csv << ["Country: " + country_name]

      second_row = ["Name(English)", "Name(Arabic)", "City", "Zone", "Country", "Location", "Latitude", "Longitude", "Status"]
      csv << second_row

      all.order_by_name.each do |area|
        @row = []
        @row << area.area
        @row << area.area_ar
        @row << area.city&.city
        @row << area.zone&.name
        @row << area.country&.name
        @row << area.location
        @row << area.latitude
        @row << area.longitude
        @row << area.status.capitalize
        csv << @row
      end
    end
  end

  def self.coverage_area_upload_format_csv
    CSV.generate do |csv|
      csv << ["country", "area", "city", "latitude", "longitude"]
    end
  end

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
      country_id = Country.find_by(name: row[0])&.id

      if country_id && row[1].present?
        area = CoverageArea.find_or_create_by(country_id: country_id, area: row[1])
        area.update(latitude: row[3], longitude: row[4])

        if row[2].present?
          city = City.find_or_create_by(city: row[2])
          area.update(city_id: city&.id)
        end
      end
    end
  end

  private

  def downcase_coverage_area_stuff
    self.area = area.downcase.titleize
  end
end
