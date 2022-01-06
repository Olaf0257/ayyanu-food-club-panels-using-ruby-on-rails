class Branch < ApplicationRecord
  # require 'geocoder'
  include Imagescaler
  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude

  belongs_to :restaurant
  belongs_to :branch_subscription, optional: true
  belongs_to :report_subscription, optional: true

  has_one :branch_bank_detail, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :pos_tables, dependent: :destroy
  has_many :branch_categories, dependent: :destroy
  has_many :categories, through: :branch_categories
  has_many :menu_categories, dependent: :destroy
  has_many :menu_items, through: :menu_categories
  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :points, dependent: :destroy
  has_many :branch_transports, dependent: :destroy
  has_many :users, through: :branch_transports
  has_many :branch_managers, dependent: :destroy
  has_many :managers, through: :branch_managers, source: :user
  has_many :branch_kitchen_managers, dependent: :destroy
  has_many :kitchen_managers, through: :branch_kitchen_managers, source: :user
  has_many :offers, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :branch_coverage_areas, dependent: :destroy
  has_many :coverage_areas, through: :branch_coverage_areas
  has_many :add_requests, dependent: :destroy
  has_many :redeem_points, dependent: :destroy
  has_many :advertisements, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :item_addon_categories, dependent: :destroy
  has_many :branch_payments, dependent: :destroy
  has_many :branch_timings, dependent: :destroy
  has_many :order_requests, dependent: :destroy
  has_many :influencer_coupon_branches, dependent: :destroy
  has_many :influencer_coupons, through: :influencer_coupon_branches
  has_many :referral_coupon_branches, dependent: :destroy
  has_many :referral_coupons, through: :referral_coupon_branches
  has_many :restaurant_coupon_branches, dependent: :destroy
  has_many :restaurant_coupons, through: :restaurant_coupon_branches
  has_many :pos_transactions, dependent: :destroy
  has_many :pos_checks, dependent: :destroy
  has_many :catering_schedules, dependent: :destroy

  before_save :downcase_branch_stuff

  attr_accessor :language
  attr_accessor :area

  # scope :closing_restaurant, -> { where("(opening_timing < closing_timing and (opening_timing > (:current_time) or closing_timing < (:current_time))) OR (opening_timing >= closing_timing and (opening_timing > (:current_time) and closing_timing < (:current_time)))", { current_time: Time.current.to_time.strftime("%H:%M") }).update_all(is_closed: true) }
  # scope :open_restaurant, -> { where("(opening_timing < closing_timing and (opening_timing <= (:current_time) and closing_timing > (:current_time))) OR (opening_timing >= closing_timing and (opening_timing <= (:current_time) or closing_timing >= (:current_time)))", { current_time: Time.current.to_time.strftime("%H:%M") }).update_all(is_closed: false) }

  scope :approved, -> { where(is_approved: true) }
  scope :order_branches, -> { order("branch_coverage_areas.position, avg_rating DESC, restaurants.title") }
  scope :is_subscribed, -> { where(report: true) }

  def as_json(options = {})
    @imgWidth = options[:imgWidth]
    @logdinUser = options[:logdinUser]
    @language = options[:language]
    @area = options[:areaWies]
    super(options.merge(except: [:created_at, :updated_at, :contact], methods: [:restaurant_name, :restaurant_logo, :image, :average_ratings, :discount, :delivery_time, :categories, :image_thumb, :is_favorite, :status, :min_order_amount, :cash_on_delivery, :accept_card, :accept_cash, :daily_timing, :delivery_charges, :contact, :is_closed, :is_busy, :call_center_no, :currency_code_en, :currency_code_ar]))
  end

  def self.open_restaurant
    if Rails.env.production?
      current_time = Time.current.to_time.strftime("%H:%M")
      branches = joins(:restaurant).where(is_approved: true, restaurants: { is_signed: true }).distinct.includes(:branch_timings).select { |b| b.opening_timing && b.closing_timing && b.opening_timing <= current_time && (b.closing_timing == "00:00" || b.closing_timing > current_time) }
      Branch.where(id: branches.pluck(:id)).update_all(is_closed: false)
    end
  end

  def self.closing_restaurant
    if Rails.env.production?
      current_time = Time.current.to_time.strftime("%H:%M")
      branches = joins(:restaurant).where(is_approved: true, restaurants: { is_signed: true }).distinct.includes(:branch_timings).select { |b| b.opening_timing && b.closing_timing && (b.opening_timing > current_time || (b.closing_timing != "00:00" && b.closing_timing < current_time)) }
      Branch.where(id: branches.pluck(:id)).update_all(is_closed: true)
    end
  end

  def opening_timing
    if branch_timings.present?
      current_time = Time.current.to_time.strftime("%H:%M")
      todays_timings = branch_timings.select { |t| BranchTiming::DAY_NAMES[t.day] == Date.today.strftime("%A")  }
      time = todays_timings.select { |t| t.opening_time <=  current_time && t.closing_time >= current_time }.first&.opening_time
      time ||= todays_timings.select { |t| t.opening_time > current_time }.sort_by(&:opening_time).first&.opening_time
      time ||= todays_timings.select { |t| t.opening_time < current_time }.sort_by(&:opening_time).last&.opening_time
      time
    else
      self["opening_timing"]
    end
  end

  def closing_timing
    if branch_timings.present?
      current_time = Time.current.to_time.strftime("%H:%M")
      todays_timings = branch_timings.select { |t| BranchTiming::DAY_NAMES[t.day] == Date.today.strftime("%A")  }
      time = todays_timings.select { |t| t.opening_time <=  current_time && t.closing_time >= current_time }.first&.closing_time
      time ||= todays_timings.select { |t| t.opening_time > current_time }.sort_by(&:opening_time).first&.closing_time
      time ||= todays_timings.select { |t| t.opening_time < current_time }.sort_by(&:opening_time).last&.closing_time
      time
    else
      self["closing_timing"]
    end
  end

  def daily_timing
    if opening_timing.present? && closing_timing.present?
      Chronic.parse(opening_timing).strftime("%I:%M%p") + "-" + Chronic.parse(closing_timing).strftime("%I:%M%p")
    else
      ""
    end
  end

  def self.approved_list_csv
    CSV.generate do |csv|
      header = "Approved Branches List"
      csv << [header]

      second_row = ["Branch Address", "Area", "Restaurant Name", "Country", "Opens at", "Closes at"]
      csv << second_row

      all.each do |branch|
        @row = []
        @row << branch.address
        @row << branch.city
        @row << branch.restaurant.title
        @row << branch.restaurant.country&.name
        @row << branch.opening_timing
        @row << branch.closing_timing
        csv << @row
      end
    end
  end

  def total_tax_percentage
    Tax.where(country_id: restaurant.country_id).sum(:percentage)
  end

  def country_tax_percentage
    Tax.where(country_id: restaurant.country_id).pluck(:percentage).join(', ')
  end

  def branch_taxes
    Tax.where(country_id: restaurant.country_id).order(:name)
  end

  def currency_code_en
    restaurant.country.currency_code.to_s
  end

  def currency_code_ar
    restaurant.country.currency_code.to_s
  end

  def call_center_no
    self[:call_center_number].presence || contact.presence || ""
  end

  def address
    if @language == "arabic"
      self["address_ar"]
    else
      self["address"]
    end
  end

  def average_ratings
    avg_rating
  end

  def discount
    # [10,20,30,40,50].sample
    offers = self.offers.where("DATE(start_date) <= (?) and DATE(end_date) >=(?) and offer_type = (?)", Date.today, Date.today, "all")
    if offers.present?
      offers.first.discount_percentage
    else
      offer = 0
    end
  end

  def branch_menus
    menu_items.as_json(only: [:item_name]).first(4)
  end

  def delivery_time
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first&.delivery_time : self["delivery_time"].to_i
    rescue Exception => e
      self["delivery_time"].to_i
    end
  end

  def cash_on_delivery
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first&.cash_on_delivery : self["cash_on_delivery"]
    rescue Exception => e
      self["cash_on_delivery"]
    end
  end

  def accept_card
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first&.accept_card : self["accept_card"]
    rescue Exception => e
      self["accept_card"]
    end
  end

  def accept_cash
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first&.accept_cash : self["accept_cash"]
    rescue Exception => e
      self["accept_cash"]
    end
  end

  def delivery_charges
    if @area.present?
      bca = branch_coverage_areas.find_by(coverage_area_id: @area)

      if bca
        if bca.third_party_delivery
          if bca.third_party_delivery_type == "Chargeable" && bca.coverage_area.latitude.present? && bca.coverage_area.longitude.present? && latitude.present? && longitude.present?
            dist = Geocoder::Calculations.distance_between([latitude, longitude], [bca.coverage_area.latitude, bca.coverage_area.longitude], units: :km).to_f.round(3)
            delivery_charge = get_delivery_charge_by_distance(dist, restaurant.country_id).to_s
          else
            delivery_charge = "0.0"
          end
        else
          delivery_charge = bca.delivery_charges
        end
      else
        delivery_charge = self["delivery_charges"]
      end
    else
      delivery_charge = self["delivery_charges"]
    end

    format("%0.03f", delivery_charge.to_f)
  end

  def min_order_amount
    if @area.present?
      bca = branch_coverage_areas.find_by(coverage_area_id: @area)

      if bca
        if bca.third_party_delivery
          if bca.coverage_area.latitude.present? && bca.coverage_area.longitude.present? && latitude.present? && longitude.present?
            dist = Geocoder::Calculations.distance_between([latitude, longitude], [bca.coverage_area.latitude, bca.coverage_area.longitude], units: :km).to_f.round(3)
            amount = get_min_order_amount_by_distance(dist, restaurant.country_id).to_s
          else
            amount = "0.0"
          end
        else
          amount = bca.minimum_amount
        end
      else
        amount = self["min_order_amount"]
      end
    else
      amount = self["min_order_amount"]
    end

    format("%0.03f", amount.to_f)
  end

  def contact
    self["contact"]
  end

  def is_closed
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first.is_closed : self["is_closed"]
    rescue Exception => e
      self["is_closed"]
    end
  end

  def is_busy
    begin
      @area.present? ? branch_coverage_areas.where(coverage_area_id: @area).first.is_busy : self["is_busy"]
    rescue Exception => e
      self["is_busy"]
    end
  end

  def is_favorite
    if @logdinUser.present?
      favorit = Favorite.where("user_id = (?) and branch_id = (?)", @logdinUser.id, id)
      if favorit.present?
        true
      else
        false
      end
    else
      false
    end
  end

  def categories
    categories = []
    # branchCategories = Branch.includes(:branch_categories)
    branch_categories.each do |cat|
      if categories.count <= 2
        if @language == "arabic"
          ar = cat.category.title_ar.presence || cat.category.title
          categories << ar
        elsif @language == "english"
          categories << cat.category.title
        end
        end
    end
    categories
  end

  def restaurant_name
    if @language == "arabic"
      restaurant.title_ar.presence || restaurant.title
    else
      restaurant.title
    end
  end

  delegate :logo, to: :restaurant, prefix: true

  def image
    self[:image]
  end

  def self.find_restaurant(_restaurnat_id)
    find(restaurant_id)
  end

  def status
    !is_closed
  end

  def self.find_area_wise_branch(area_id)
    branches = Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("branch_coverage_areas.coverage_area_id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", area_id, true, true, true, true, true).order_branches.distinct

    target_branches = area_id.present? ? branches : Branch.joins(:restaurant, :branch_coverage_areas).where("restaurants.is_signed = (?)", true).distinct.order_branches
  end

  def self.find_restaurant_Branch(page, per_page, area_id)
    branches = Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("branch_coverage_areas.coverage_area_id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", area_id, true, true, true, true, true).order_branches.distinct

    target_branches = area_id.present? ? branches : Branch.joins(:restaurant, :branch_coverage_areas).where("restaurants.is_signed = (?)", true).distinct.order_branches

    target_branches.each do |b|
      b.area = area_id
    end

    target_branches.sort_by { |b| !b.is_closed && !b.is_busy ? 0 : 1 }.paginate(page: page, per_page: per_page)
  end

  def self.find_restaurants(_page, _per_page, _area_id)
    branches = Restaurant.joins(:branches).where("is_signed = ? and is_approved = ?", true, true).distinct(&:restaurant_id).paginate(page: 1, per_page: 10)
  end

  def self.find_web_restaurant_Branch(_page, _per_page, area_id)
    branches = Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("branch_coverage_areas.coverage_area_id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", area_id, true, true, true, true, true).order_branches.distinct(&:restaurnat_id).paginate(page: 1, per_page: 10)

    area_id.present? ? branches : Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("restaurants.is_signed = (?)  and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", true, true, true, true, true).order_branches.distinct(&:restaurant_id).paginate(page: 1, per_page: 10)
  end

  def self.find_all_restaurant_Branch(area_id, sort_key, _sort_by, offres, free_delivery, open_restaurant, payment_method, page, per_page, category_id, new_restaurant)
    branches = Branch.joins(:branch_coverage_areas, :restaurant, menu_categories: [:menu_items]).where("branch_coverage_areas.coverage_area_id = ? and restaurants.is_signed = (?) and menu_categories.id IS NOT NULL and menu_category_id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_items.approve = ? and menu_items.is_available = (?) and branches.is_approved = (?)", area_id, true, true, true, true, true)

    if payment_method == "card"
      branches = branches.where(branch_coverage_areas: { accept_card: true })
    elsif payment_method == "cash"
      branches = branches.where(branch_coverage_areas: { cash_on_delivery: true })
    end

    branches = branches.joins(:offers).where("DATE(offers.start_date) <= (?) and DATE(offers.end_date) >=(?) AND offers.is_active = ?", Time.zone.today, Time.zone.today, true) if offres == "true"
    branches = branches.where("(branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.delivery_charges = ?) OR (branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.third_party_delivery_type = ?)", false, "0", true, "Free") if free_delivery == "true"
    branches = branches.where(branch_coverage_areas: { is_closed: false }) if open_restaurant == "true"
    branches = branches.where("DATE(branch_coverage_areas.created_at) >= ?", (Time.zone.today - 30)) if new_restaurant == "true"
    branches = branches.joins(:branch_categories).where(branch_categories: { category_id: category_id }) if category_id.present?
    branches = branches.distinct.order_branches

    branches = if sort_key == "a_to_z"
                 branches.order("restaurants.title")
               elsif sort_key == "price"
                 branches.includes(:branch_coverage_areas).sort_by { |b| b.branch_coverage_areas.find_by(coverage_area_id: area_id).min_order_amount.to_f }
               elsif sort_key == "fastest_delivery"
                 branches.order("branch_coverage_areas.delivery_time")
               else
                 branches
               end

    branches.each do |b|
      b.area = area_id
    end

    branches.sort_by { |b| !b.is_closed && !b.is_busy ? 0 : 1 }.paginate(page: page, per_page: per_page)
  end

  def self.find_branch(branch_id)
    find_by(id: branch_id)
  end

  def self.find_branch_menu(branch)
    menuCategories = branch.menu_categories.joins(:menu_items).where("menu_categories.id IS NOT NULL and menu_categories.available = true and menu_categories.approve = ? and menu_category_id IS NOT NULL and menu_items.approve = ? and menu_items.is_available = (?)and menu_items.approve = (?) and (DATE(start_date) IS NULL or TIME(end_time) IS NULL) or (DATE(start_date) <= ? and DATE(end_date) >= ? and start_time <= ? and end_time > ?)", true, true, true, true, Date.today, Date.today, Time.now, Time.now).includes(:menu_items).order(:category_priority, :category_title)
  end

  def self.get_most_selling_data(branch, user, guestToken, image_width, language, area_id)
    orders = Order.joins({ branch: :branch_coverage_areas }, { order_items: { menu_item: :menu_category } }).where(menu_items: { approve: true, is_available: true }, branch_coverage_areas: { coverage_area_id: area_id }, menu_categories: { approve: true, available: true }).where("orders.branch_id IN (?) AND (menu_items.far_menu = ? OR branch_coverage_areas.far_menu = ?)", branch.id, true, false).group("menu_item_id").order("count(menu_item_id) DESC").limit(10)

    if orders.present?
      if language == "arabic"
        category = { "id" => 0, "approve" => true, "is_rejected" => false, "resion" => "", "start_date" => nil, "end_date" => nil, "start_time" => nil, "end_time" => nil, "category_title" => "الأكثر مبيعا", "dish_end_time" => "", "items" => [] }
      else
        category = { "id" => 0, "approve" => true, "is_rejected" => false, "resion" => "", "start_date" => nil, "end_date" => nil, "start_time" => nil, "end_time" => nil, "category_title" => "Most Selling", "dish_end_time" => "", "items" => [] }
      end

      orders.count.each do |order|
        item = MenuItem.find_by(id: order.first)

        if item.menu_item_dates.blank? || item.menu_item_dates.select { |i| i.menu_date == Date.today  }.present?
          category["items"] << item.as_json(imgWidth: image_width, logdinUser: user, guestToken: guestToken, language: language, branch: branch)
        end
      end
      category
    end
  rescue Exception => e
  end

  def self.find_branch_menu_for_business(branch)
    branch.menu_categories.includes(menu_items: [{ item_addon_categories: :item_addons }]).order("category_priority asc")
  end

  def image_thumb
    img_thumb(restaurant.images.first.url, @imgWidth) if restaurant.images.first
  rescue Exception => e
  end

  def coverage_area
    coverage_areas.first
  end

  def self.find_restaurant_all_Branch(restaurant_id)
    Branch.where(restaurant_id: restaurant_id)
  end

  def self.web_filter_by_criteria(filter, area_id)
    case filter
    when "offers" then joins(:offers).where("DATE(offers.start_date) <= (?) and DATE(offers.end_date) >=(?) AND offers.is_active = ?", Date.today, Date.today, true)
    when "free_delivery" then where(branch_coverage_areas: { coverage_area_id: area_id }).where("(branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.delivery_charges = ?) OR (branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.third_party_delivery_type = ?)", false, "0", true, "Free")
    when "open_restaurants" then where("branch_coverage_areas.coverage_area_id = ? AND branch_coverage_areas.is_closed = ?", area_id, false)
    when "new_restaurants" then where("branch_coverage_areas.coverage_area_id = ?  AND DATE(branch_coverage_areas.created_at) >= ?", area_id, (Date.today - 30))
    else
      all
    end
  end

  def self.web_find_all_resturant(keyword, page, per_page)
    if keyword.present?
      Restaurant.joins(:branches).where("title LIKE (?) and is_signed = ? and is_approved = ? and branches.is_approved = (?)", "%#{keyword}%", true, true, true).distinct(&:restaurant_id).paginate(page: page, per_page: per_page)
    else
      Restaurant.joins(:branches).where("is_signed = ? and is_approved = ? and branches.is_approved = (?)", true, true, true).distinct(&:restaurant_id).paginate(page: page, per_page: per_page)
    end
  end

  def self.set_subscribe_branch(branch, status)
    case status
    when "true"
      branch_report = current_month_branch_report(branch)
      if branch_report.present?
        { code: 200, message: "Already subscribed branch for this month!!" }
      else
        Subscription.add_subscribe_report(nil, branch)
        { code: 200, message: "Successfully subscribe branch." }
      end
    when "false"
      branch_report = current_month_branch_report(branch)
      branch_report.last.update(unsubscribe_date: Date.today, is_subscribe: false) # , report_expaired_at: Date.today.end_of_month)
      { code: 200, message: "Successfully unsubscribe branch." }
    end
  end

  def self.current_month_branch_report(branch)
    branch.subscriptions.where("(DATE(subscribe_date) <= ? and is_subscribe = ?) or (MONTH(subscribe_date) = ? and is_subscribe = ?)", Date.today, true, Date.today.month, false)
  end

  #==========Web panel (Business)=====
  def self.branch(restaurant, address, contact, max_delivery_time, minimum_order_amount, cash_on_delivery, acept_cash, accept_card, _country, area_id, tax_percentage, delivery_charges, url, latitude, longitude, cr_url, cpr_url)
    areaDetails = CoverageArea.find_by(id: area_id)

    branch = new(address: address, city: areaDetails.area, contact: contact, restaurant_id: restaurant.id, delivery_time: max_delivery_time, delivery_charges: delivery_charges, cash_on_delivery: cash_on_delivery, accept_cash: acept_cash, accept_card: accept_card, min_order_amount: minimum_order_amount, tax_percentage: tax_percentage.presence || "5.000", image: url, is_approved: false, latitude: latitude, longitude: longitude, cr_document: cr_url, cpr_document: cpr_url)

    branch.save!
    !branch.id.nil? ? { code: 200, result: branch } : { code: 400, result: branch.errors.full_messages.join(", ") }
  end

  def import(file)
    return unless open_spreadsheet(file)
    spreadsheets = open_spreadsheet(file).workbook.worksheets
    menu_category_sheet = spreadsheets[0]
    item_addon_category_sheet = spreadsheets[1]
    menu_item_sheet = spreadsheets[2]
    item_addon_sheet = spreadsheets[3]

    menu_category_sheet.rows.each_with_index do |row, i|
      next if i.zero?
      menu_category = menu_categories.find_by(category_title: row[0]) || menu_categories.new

      if menu_category.persisted? && row[0].present? && row[1].present?
        menu_category.update(category_title: row[0].to_s.strip, categroy_title_ar: row[1].to_s.strip, branch_id: id, category_priority: row[2])
      elsif row[0].present? && row[1].present?
        menu_cat = MenuCategory.newMenuCategory(row[0].to_s.strip, row[1].to_s.strip, id, false, true)
        menu_cat&.update(category_priority: row[2])
      end
    end

    item_addon_category_sheet.rows.each_with_index do |row, i|
      next if i.zero?
      item_addon_category = item_addon_categories.find_by(addon_category_name: row[0]) || item_addon_categories.new

      if item_addon_category.persisted? && row[0].present? && row[1].present?
        item_addon_category.update(min_selected_quantity: row[2].to_s.presence || 0, max_selected_quantity: row[3].to_s.presence || 0, addon_category_name_ar: row[1].to_s.strip)
      elsif row[0].present? && row[1].present?
        ItemAddonCategory.create_new_addon_category(self, row[0].to_s.strip, row[1].to_s.strip, row[2].to_s.presence || 0, row[3].to_s.presence || 0, false, true)
      end
    end

    menu_item_sheet.each_with_index do |row, i|
      next if i.zero? || i == 1
      menu_category = menu_categories.find_by(category_title: row[4])

      next unless menu_category
      menu_item = menu_category.menu_items.find_by(item_name: row[0]) || menu_category.menu_items.new

      if menu_item.persisted? && row[0].present? && row[1].present? && row[2].present? && row[3].present? && row[4].present? && row[5].present? && row[6].present?
        target_item = menu_item
        menu_item.update(item_description: row[1].to_s.strip, item_name_ar: row[2].to_s.strip, item_description_ar: row[3].to_s.strip, menu_category_id: menu_category.id, price_per_item: row[5], calorie: row[6], is_available: row[7].to_s.strip == "Available", item_image: row[9].to_s.strip)
      elsif row[0].present? && row[1].present? && row[2].present? && row[3].present? && row[4].present? && row[5].present? && row[6].present?
        MenuItem.newMenuItem(row[0].to_s.strip, row[5], "", row[1].to_s.strip, menu_category.id, row[7].to_s.strip == "Available", row[2].to_s.strip, row[3].to_s.strip, row[6], false, "", "", true)
        target_item = MenuItem.last
        target_item&.update(item_image: row[9].strip) if row[9]
      end

      item_addon_cat = row[8].to_s.split(", ")

      next if item_addon_cat.blank?
      target_item.menu_item_addon_categories.destroy_all

      item_addon_cat&.each do |cat|
        cat_id = item_addon_categories.find_by(addon_category_name: cat)&.id
        target_item.menu_item_addon_categories.create(item_addon_category_id: cat_id) if cat_id
      end
    end

    item_addon_sheet.rows.each_with_index do |row, i|
      next if i.zero?
      item_addon_category = item_addon_categories.find_by(addon_category_name: row[3])

      next unless item_addon_category
      item_addon = item_addon_category.item_addons.find_by(addon_title: row[0]) || item_addon_category.item_addons.new

      if item_addon.persisted? && row[0].present? && row[1].present? && row[2].present?
        item_addon.update(addon_title: row[0].to_s.strip, addon_price: row[2], item_addon_category_id: item_addon_category.id, addon_title_ar: row[1].to_s.strip)
      elsif row[0].present? && row[1].present? && row[2].present?
        ItemAddon.create_new_addon_item(item_addon_category, row[0].to_s.strip, row[2], row[1].to_s.strip, false, true)
      end
    end
  end

  def open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".xls" then Roo::Excel.new(file.path)
    else nil
    end
  rescue Exception => e
  end

  def category_names
    Category.where(id: branch_categories.pluck(:category_id).uniq).pluck(:title).sort
  end

  def self.branch_charges_report_csv
    CSV.generate do |csv|
      header = "Branch Charges Report"
      csv << [header]

      second_row = ["Restaurant", "Branch", "Branch Subscription Fee", "Report Subscription Fee", "Total Fee", "Fixed Charge (%)", "Fixed Charge Capping"]
      csv << second_row

      all.each do |branch|
        currency = branch.currency_code_en
        @row = []
        @row << branch.restaurant.title
        @row << branch.address
        @row << (branch.branch_subscription.present? ? (ApplicationController.helpers.number_with_precision(branch.branch_subscription.fee, precision: 3).to_s + " " + currency) : "")
        @row << (branch.report_subscription.present? ? (ApplicationController.helpers.number_with_precision(branch.report_subscription.fee, precision: 3).to_s + " " + currency) : "")
        @row << ApplicationController.helpers.number_with_precision((branch.report_subscription&.fee.to_f + branch.branch_subscription&.fee.to_f), precision: 3).to_s + " " + currency
        @row << branch.fixed_charge_percentage
        @row << (branch.max_fixed_charge.present? ? (ApplicationController.helpers.number_with_precision(branch.max_fixed_charge, precision: 3).to_s + " " + currency) : "")
        csv << @row
      end
    end
  end

  #===================================

  private

  def downcase_branch_stuff
    self.address = address.capitalize
  end

  def get_delivery_charge_by_distance(distance, country_id)
    charge = 0

    DistanceDeliveryCharge.where(country_id: country_id).each do |d|
      range = d.min_distance...d.max_distance

      if range.cover?(distance)
        charge = d.charge
        break
      end
    end

    charge
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
