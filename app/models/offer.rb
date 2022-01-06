class Offer < ApplicationRecord
  TIME_LIST = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"].freeze

  belongs_to :branch
  belongs_to :menu_item, optional: true
  belongs_to :admin_offer, optional: true
  has_many :pos_checks

  before_save :downcase_offer_stuff

  scope :active, -> { where(is_active: true) }
  scope :running, -> { where(id: has_quantity.where("DATE(offers.start_date) <= ? AND DATE(offers.end_date) >= ?", Date.today, Date.today).select { |o| o.start_time.nil? || o.end_time.nil? or (o.start_time&.strftime("%H:%M") <= Time.zone.now.strftime("%H:%M") && o.end_time&.strftime("%H:%M") >= Time.zone.now.strftime("%H:%M")) }.map(&:id).uniq) }
  scope :has_quantity, -> { where("offers.limited_quantity = ? OR (offers.limited_quantity = ? AND offers.quantity > 0)", false, true) }

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :branch_id, :offer_type, :branch_address], methods: [:restaurant_id, :restaurant_name, :restaurant_logo]))
    end

  def self.find_offers_list(area_id, page, per_page)
    joins(branch: [:branch_coverage_areas, :restaurant]).where(branches: { is_approved: true }, restaurants: { is_signed: true }).where("coverage_area_id = (?) and DATE(start_date) <= (?) and DATE(end_date) >=(?)", area_id, Date.today, Date.today).paginate(page: page, per_page: per_page).uniq
  end

  def self.find_all_offers_list(page, per_page)
    joins(branch: :restaurant).where(branches: { is_approved: true }, restaurants: { is_signed: true }).where("DATE(start_date) <= (?) and DATE(end_date) >=(?)", Date.today, Date.today).distinct.paginate(page: page, per_page: per_page)
  end

  def offer_title
    admin_offer&.offer_title.presence || self[:offer_title]
  end

  def discount_percentage
    admin_offer&.offer_percentage.presence || self[:discount_percentage]
  end

  def offer_image
    admin_offer&.offer_image.presence || self[:offer_image]
  end

  def restaurant_name
    branch.restaurant.title
  end

  def restaurant_logo
    branch.restaurant.logo
  end

  delegate :restaurant_id, to: :branch

  def self.find_offers(offer, language)
    areas = []
    offer = find_by(id: offer)
    offer.branch.branch_coverage_areas.each do |area|
      branchHash = {}
      branch = {}
      branchHash["id"] = area.coverage_area.id
      branchHash["area"] = language == "english" ? area.coverage_area.area : area.coverage_area.area_ar
      branch["branch_id"] = area.branch_id
      branchHash["branch"] = branch
      areas << branchHash
    end
    areas
  end

  def self.add_new_offer(branch_id, menu_item_id, offer_type, discount_percentage, start_date, end_date, offer_title)
    offer = create(branch_id: branch_id, offer_type: offer_type, discount_percentage: discount_percentage, menu_item_id: menu_item_id, start_date: start_date + " " + Time.now.strftime("%H:%M:%S"), end_date: end_date + " " + Time.now.strftime("%H:%M:%S"), offer_title: offer_title)
  end

  def self.find_restaurant_offers(branches)
    where(branch_id: branches.pluck(:id))
  end

  def self.find_branch_offer(branch)
    where(branch_id: branch)
  end

  def self.offer_menu_item(branch, offer_title, start_date, end_date, menu_item, discount_percentage, url, offer_type)
    create(discount_percentage: discount_percentage, start_date: start_date + " " + Time.now.strftime("%H:%M:%S"), end_date: end_date + " " + Time.now.strftime("%H:%M:%S"), offer_title: offer_title, branch_id: branch.id, menu_item_id: offer_type == "individual" ? menu_item : "", offer_image: url, offer_type: offer_type)
  end

  def self.find_menu_offer(offer_id)
    find_by(id: offer_id)
  end

  def self.business_offer_list_csv(offer)
    CSV.generate do |csv|
      header = "Business Offer List"
      csv << [header]
      csv << ["Offer Title:" + offer.offer_title]

      second_row = ["S.no", "Offer Title", "Menu Item Title", "Restaurant", "Branch", "Discount %", "Qty", "Start Date", "End Date", "Status", "Active/Deactive"]
      csv << second_row

      all.each do |offer|
        @row = []
        @row << offer.id
        @row << (offer.offer_title.presence || "N/A")
        @row << (offer.menu_item&.item_name.presence || "All")
        @row << (offer.branch.restaurant.title)
        @row << (offer.branch&.address.presence || "")
        @row << offer.discount_percentage
        @row << offer.quantity
        @row << offer.start_date&.strftime("%Y/%m/%d").to_s + " " + offer.start_time&.strftime("%I:%M%p").to_s
        @row << offer.end_date&.strftime("%Y/%m/%d").to_s + " " + offer.end_time&.strftime("%I:%M%p").to_s
        @row << status = (offer.is_active == false) ? "Deactive" : offer.start_date ? (offer.start_date.to_date <= Date.today && offer.end_date && offer.end_date.to_date >= Date.today) ? "Running" : (offer.start_date.to_date > Date.today) ? "Upcoming" : "Closed" : "Closed"
        @row << state = (offer.end_date && offer.end_date.to_date >= Date.today) ? offer.is_active ? "Active" : "Deactive" : ""
        csv << @row
      end
    end
  end

  def self.sweet_deal_offer_list_csv
    CSV.generate do |csv|
      header = "Sweet Deal Offer List"
      csv << [header]

      second_row = ["S.no", "Offer Title", "Menu Item Title", "Restaurant", "Branch", "Discount %", "Qty", "Start Date", "End Date", "Status", "Active/Deactive"]
      csv << second_row

      all.each do |offer|
        @row = []
        @row << offer.id
        @row << (offer.offer_title.presence || "N/A")
        @row << (offer.menu_item&.item_name.presence || "All")
        @row << (offer.branch.restaurant.title)
        @row << (offer.branch&.address.presence || "")
        @row << offer.discount_percentage
        @row << offer.quantity
        @row << offer.start_date&.strftime("%Y/%m/%d").to_s + " " + offer.start_time&.strftime("%I:%M%p").to_s
        @row << offer.end_date&.strftime("%Y/%m/%d").to_s + " " + offer.end_time&.strftime("%I:%M%p").to_s
        @row << status = (offer.is_active == false) ? "Deactive" : offer.start_date ? (offer.start_date.to_date <= Date.today && offer.end_date && offer.end_date.to_date >= Date.today) ? "Running" : (offer.start_date.to_date > Date.today) ? "Upcoming" : "Closed" : "Closed"
        @row << state = (offer.end_date && offer.end_date.to_date >= Date.today) ? offer.is_active ? "Active" : "Deactive" : ""
        csv << @row
      end
    end
  end


  private

  def downcase_offer_stuff
    self.offer_title = offer_title&.downcase&.titleize
  end
end
