class BranchCoverageArea < ApplicationRecord
  DELIVERY_TYPE = [["Restaurant", false], ["Food Club", true]]

  belongs_to :branch
  belongs_to :coverage_area

  before_save :populate_payment_options

  # scope :closing_restaurant_area, -> { joins(:branch).where("(opening_timing < closing_timing and (opening_timing > (:current_time) or closing_timing < (:current_time))) OR (opening_timing >= closing_timing and (opening_timing > (:current_time) and closing_timing < (:current_time)))", { current_time: Time.current.to_time.strftime("%H:%M") }).update_all(is_closed: true) }
  # scope :open_restaurant_area, -> { joins(:branch).where("(opening_timing < closing_timing and (opening_timing <= (:current_time) and closing_timing > (:current_time))) OR (opening_timing >= closing_timing and (opening_timing <= (:current_time) or closing_timing >= (:current_time)))", { current_time: Time.current.to_time.strftime("%H:%M") }).update_all(is_closed: false) }

  scope :order_by_restaurant_title, -> { order("restaurants.title") }

  def self.add_branch_area(delivery_charges, minimum_amount, delivery_time, daily_open_at, daily_closed_at, branch_id, coverage_area_id, cash_on_delivery, accept_cash, accept_card)
    create(delivery_charges: delivery_charges, minimum_amount: minimum_amount, delivery_time: delivery_time, daily_open_at: daily_open_at, daily_closed_at: daily_closed_at, branch_id: branch_id, coverage_area_id: coverage_area_id, cash_on_delivery: cash_on_delivery, accept_cash: accept_cash, accept_card: accept_card)
  end

  def self.open_restaurant_area
    if Rails.env.production?
      current_time = Time.current.to_time.strftime("%H:%M")
      areas = joins(branch: :restaurant).where(branches: { is_approved: true }, restaurants: { is_signed: true }).distinct.includes(branch: :branch_timings).select { |b| b.branch.opening_timing && b.branch.closing_timing && b.branch.opening_timing <= current_time && (b.branch.closing_timing == "00:00" || b.branch.closing_timing > current_time) }
      BranchCoverageArea.where(id: areas.pluck(:id)).update_all(is_closed: false)
    end
  end

  def self.closing_restaurant_area
    if Rails.env.production?
      current_time = Time.current.to_time.strftime("%H:%M")
      areas = joins(branch: :restaurant).where(branches: { is_approved: true }, restaurants: { is_signed: true }).distinct.includes(branch: :branch_timings).select { |b| b.branch.opening_timing && b.branch.closing_timing && (b.branch.opening_timing > current_time || (b.branch.closing_timing != "00:00" && b.branch.closing_timing < current_time)) }
      BranchCoverageArea.where(id: areas.pluck(:id)).update_all(is_closed: true)
    end
  end

  def min_order_amount
    if third_party_delivery
      if coverage_area.latitude.present? && coverage_area.longitude.present? && branch.latitude.present? && branch.longitude.present?
        dist = Geocoder::Calculations.distance_between([branch.latitude, branch.longitude], [coverage_area.latitude, coverage_area.longitude], units: :km).to_f.round(3)
        amount = get_min_order_amount_by_distance(dist, coverage_area.country_id).to_s
      else
        amount = 0.0
      end
    else
      amount = minimum_amount
    end

    amount
  end

  def area_name
    coverage_area.area
  end

  def self.get_branch_coverage_area(area_id, branch_id)
    find_by(coverage_area_id: area_id, branch_id: branch_id)
  end

  def self.search_by_keyword(country_id, criteria, keyword)
    result = all
    result = result.where(restaurants: { country_id: country_id }) if country_id.present?
    result = result.where("restaurants.title like ?", "#{keyword}%") if criteria == "Restaurant"
    result = result.where("branches.address like ?", "#{keyword}%") if criteria == "Branch"
    result = result.where("coverage_areas.area like ?", "#{keyword}%") if criteria == "Area"
    result
  end

  def self.busy_list_csv
    CSV.generate do |csv|
      header = "Busy Restaurants List"
      csv << [header]

      second_row = ["Restaurant", "Branch", "Area", "Country"]
      csv << second_row

      all.each do |bca|
        @row = []
        @row << bca.branch.restaurant.title
        @row << (bca.branch&.address.presence || "Not available")
        @row << bca.coverage_area.area
        @row << (bca.branch.restaurant.country&.name.presence || "NA")
        csv << @row
      end
    end
  end

  def self.closed_list_csv
    CSV.generate do |csv|
      header = "Closed Restaurants List"
      csv << [header]

      second_row = ["Restaurant", "Branch", "Area", "Country"]
      csv << second_row

      all.each do |bca|
        @row = []
        @row << bca.branch.restaurant.title
        @row << (bca.branch&.address.presence || "Not available")
        @row << bca.coverage_area.area
        @row << (bca.branch.restaurant.country&.name.presence || "NA")
        csv << @row
      end
    end
  end

  def self.free_delivery_list_csv
    CSV.generate do |csv|
      header = "Free Delivery Branches"
      csv << [header]

      second_row = ["Restaurant Name", "Branch Address", "Area", "Country", "Delivery Type"]
      csv << second_row

      all.each do |bca|
        @row = []
        @row << bca.branch.restaurant.title
        @row << bca.branch.address
        @row << bca.coverage_area.area
        @row << (bca.branch.restaurant.country&.name.presence || "NA")
        @row << (bca.third_party_delivery ? "Food Club" : "Restaurant")
        csv << @row
      end
    end
  end

  def payment_methods
    methods = []
    methods << "Online" if accept_card
    methods << "Credit Card Machine" if accept_cash
    methods << "Cash" if cash_on_delivery
    methods.join(", ")
  end

  private

  def populate_payment_options
    self.cash_on_delivery = false if cash_on_delivery.nil?
    self.accept_cash = false if accept_cash.nil?
    self.accept_card = false if accept_card.nil?
  end

  def get_min_order_amount_by_distance(distance, country_id)
    amount = 0

    DistanceDeliveryCharge.where(country_id: country_id).each do |d|
      range = d.min_distance...d.max_distance

      if range.cover?(distance)
        amount = d.min_order_amount
        break
      end
    end

    amount
  end
end
