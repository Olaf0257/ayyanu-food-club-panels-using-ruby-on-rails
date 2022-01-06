class Restaurant < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :user, optional: true
  has_many :images, dependent: :destroy
  has_one :branch, dependent: :destroy
  has_many :branches, dependent: :destroy
  has_many :task_types, dependent: :destroy
  has_many :suggest_restaurants, dependent: :destroy
  has_many :advertisements, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_one :restaurant_document, dependent: :destroy
  has_many :order_reviews, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :over_groups, dependent: :destroy
  has_many :major_groups, dependent: :destroy
  has_many :item_groups, dependent: :destroy
  has_many :recipe_groups, dependent: :destroy
  has_many :combo_meal_groups, dependent: :destroy
  has_many :store_types, dependent: :destroy
  has_many :stores, dependent: :destroy
  has_many :stations, dependent: :destroy
  has_many :production_groups, dependent: :destroy
  has_many :brands, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :account_types, dependent: :destroy
  has_many :account_categories, dependent: :destroy
  has_one :new_restaurant, dependent: :destroy
  has_many :card_types, dependent: :destroy
  has_many :departments, dependent: :destroy
  has_many :banks, dependent: :destroy
  has_many :vendors, dependent: :destroy
  has_many :asset_categories, dependent: :destroy
  has_many :asset_types, dependent: :destroy
  has_many :designations, dependent: :destroy
  has_many :document_stages, dependent: :destroy
  has_many :stages, dependent: :destroy
  has_many :assets, dependent: :destroy
  has_many :manuals, dependent: :destroy
  has_many :manual_categories, dependent: :destroy
  has_many :stations, dependent: :destroy
  has_many :chapters, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :receive_orders, dependent: :destroy
  has_many :transfer_orders, dependent: :destroy
  has_many :shifts, dependent: :destroy
  has_many :task_lists
  before_save :downcase_restaurant_details_stuff
  has_many :cash_types, dependent: :destroy
  has_many :kds_colors, dependent: :destroy

  validates :title, presence: true

  attr_accessor :language

  scope :pending_name_update_request_list, -> { where("temp_title is not null or temp_title_ar is not null") }

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :user_id]))
  end

  def branch_countries
    Country.where(name: branches.pluck(:country).uniq)
  end

  def currency_code_en
    country&.currency_code.to_s
  end

  def currency_code_ar
    country&.currency_code.to_s
  end

  def title
    if @language == "arabic"
      self["title_ar"]
    else
      self["title"]
    end
  end

  def self.find_restaurant_list(keyword, page, per_page, country)
    perPage = per_page ? per_page : 20

    if country == "All"
      if keyword.present?
        Restaurant.includes(:user, :restaurant_document).where("title LIKE ?", "%#{keyword}%").paginate(page: page, per_page: perPage)
      else
        Restaurant.includes(:user, :restaurant_document).paginate(page: page, per_page: perPage)
      end
    else
      if keyword.present?
        Restaurant.includes(:user, :restaurant_document).where(country_id: country).where("title LIKE ?", "%#{keyword}%").paginate(page: page, per_page: perPage)
      else
        Restaurant.includes(:user, :restaurant_document).where(country_id: country).paginate(page: page, per_page: perPage)
      end
    end
  end

  def self.find_pending_update_request_list(keyword, country_id, status)
    restaurants = all
    restaurants = restaurants.where(country_id: country_id) if country_id.present?
    restaurants = restaurants.where("title LIKE ?", "%#{keyword}%") if keyword.present?
    restaurants = restaurants.where(approved: false, rejected: false) if status.to_s == "Pending"
    restaurants = restaurants.where(approved: true) if status.to_s == "Approved"
    restaurants = restaurants.where(rejected: true) if status.to_s == "Rejected"
    restaurants
  end

  def self.restaurant_branches(user_id)
    find_by(user_id: user_id)
  end

  def self.find_restaurant(_restaurnat_id)
    find(restaurant_id)
  end

  def self.create_restaurant(req_restaurant, user)
    restaurant = new(title: req_restaurant.restaurant_name, user_id: user[:result].id, is_signed: false, country_id: req_restaurant.country_id)

    if restaurant.save!
      restaurant.branches.create(address: "", city: req_restaurant.coverage_area&.area.to_s, country: req_restaurant.country&.name.to_s, tax_percentage: 5, daily_timing: "")
    end
  end

  def self.get_restaurant_by_title(keyword)
    Restaurant.where("title LIKE ? or id = ? ", "#{keyword}%", keyword).first
  end

  def restaurant_avg_rating
    branches = self.branches
    avg_rating = branches.pluck(:avg_rating).sum / branches.count
  end

  def self.find_all_enable_list(keyword, page, per_page)
    if keyword.present?
      where("title LIKE ? and is_signed = ?", "#{keyword}%", true).paginate(page: page, per_page: per_page)
    else
      where("is_signed = ?", true).paginate(page: page, per_page: per_page)
    end
  end

  def self.cuisine_restaurants_list_csv(category)
    CSV.generate do |csv|
      header = "Cuisine Restaurant List"
      csv << [header]
      csv << ["Restaurants under " + category.title + " Cuisine"]

      second_row = ["S.No", "Restaurants"]
      csv << second_row

      all.order(:title).each_with_index do |order, index|
        @row = []
        @row << index += 1
        @row << order.title
        csv << @row
      end
    end
  end

  def self.name_approval_restaurant_list_csv
    CSV.generate do |csv|
      header = "Restaurants Pending Name Change Approval List"
      csv << [header]

      second_row = ["ID", "Current Name", "New Name", "Current Name (Arabic)", "New Name (Arabic)", "Owner Name", "Country", "Requested On", "Status"]
      csv << second_row

      all.each do |restaurant|
        @row = []
        @row << restaurant.id
        @row << restaurant.title
        @row << restaurant.temp_title
        @row << restaurant.title_ar
        @row << restaurant.temp_title_ar
        @row << restaurant.user&.name
        @row << restaurant.country&.name
        @row << restaurant.name_change_requested_on&.strftime("%d/%m/%Y")

        if (restaurant.approved == false and restaurant.rejected == false)
          @row << "PENDING"
        elsif restaurant.approved == true
          @row << "APPROVED"
        elsif
          @row << "REJECTED"
        end

        csv << @row
      end
    end
  end

  def self.all_restaurant_list_csv
    CSV.generate do |csv|
      header = "All Restaurant List"
      csv << [header]

      second_row = ["ID", "Name", "Name (Arabic)", "Country", "Joined", "Status"]
      csv << second_row

      all.each do |restaurant|
        @row = []
        @row << restaurant.id
        @row << restaurant.title
        @row << restaurant.title_ar
        @row << restaurant.country&.name
        @row << restaurant.created_at.strftime("%d/%m/%Y")
        @row << (restaurant.is_signed ? "ENABLED" : "DISABLED")
        csv << @row
      end
    end
  end

  private

  def downcase_restaurant_details_stuff
    self.title = title.to_s.strip
    self.title_ar = title_ar.to_s.strip
    self.country_id = 15 if country_id.nil?
  end
end
