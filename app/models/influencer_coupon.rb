class InfluencerCoupon < ApplicationRecord
  belongs_to :user

  has_many :influencer_coupon_branches, dependent: :destroy
  has_many :influencer_coupon_menu_items, dependent: :destroy
  has_many :influencer_coupon_users, dependent: :destroy

  has_many :branches, through: :influencer_coupon_branches
  has_many :menu_items, through: :influencer_coupon_menu_items

  validates :discount, :quantity, :total_quantity, presence: true
  validates :coupon_code, presence: true, uniqueness: true
  validate :date_validation, :code_validation

  scope :active, -> { where(active: true) }
  scope :order_by_date, -> { order(start_date: :desc) }

  def self.filter_by_keyword(country_id, keyword, start_date, end_date)
    coupons = all
    coupons = coupons.where(users: { country_id: country_id }) if country_id.present?
    coupons = coupons.joins(:user, branches: :restaurant).where("coupon_code like ? OR users.name like ? OR restaurants.title like ?", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%") if keyword.present?
    coupons = coupons.where("DATE(influencer_coupons.start_date) <= ? AND DATE(influencer_coupons.end_date) >= ?", start_date.to_date, start_date.to_date) if start_date.present?
    coupons = coupons.where("DATE(influencer_coupons.start_date) <= ? AND DATE(influencer_coupons.end_date) >= ?", end_date.to_date, end_date.to_date) if end_date.present?
    coupons
  end

  def current_status
    if !active
      "DEACTIVATED"
    elsif end_date < Date.today
      "CLOSED"
    elsif start_date > Date.today
      "UPCOMING"
    else
      "RUNNING"
    end
  end

  def quantity_used
    total_quantity - quantity
  end

  def self.influencer_coupon_list_csv(country_id, start_date, end_date)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "Influencer Coupons List"
      csv << [header]

      csv << ["Country: " + country_name, "Start Date: " + start_date, "End Date: " + end_date]
      second_row = ["Influencer", "Coupon Code", "Discount (%)", "Total Quantity", "Quantity Left", "Start Date", "End Date", "Country", "Status", "Notes", "Restaurants"]
      csv << second_row

      all.order_by_date.each do |coupon|
        @row = []
        @row << coupon.user.name
        @row << coupon.coupon_code
        @row << coupon.discount
        @row << coupon.total_quantity
        @row << coupon.quantity
        @row << coupon.start_date.strftime("%d/%m/%Y")
        @row << coupon.end_date.strftime("%d/%m/%Y")
        @row << coupon.user.country&.name
        @row << coupon.current_status
        @row << coupon.notes
        @row << (coupon.branches.map(&:restaurant).map(&:title).flatten.uniq.sort.join(" | ").presence || "All Restaurants")
        csv << @row
      end
    end
  end

  private

  def date_validation
    errors.add(:base, "End Date should be greater than Start Date") if self[:start_date] >= self[:end_date]
  end

  def code_validation
    existing_referral_coupon = ReferralCoupon.where(coupon_code: self[:coupon_code])
    existing_restaurant_coupon = RestaurantCoupon.where(coupon_code: self[:coupon_code])

    if existing_referral_coupon.present?
      errors.add(:base, "This Coupon Code is already in use as Referral Coupon")
    elsif existing_restaurant_coupon.present?
      errors.add(:base, "This Coupon Code is already in use as Restaurant Coupon")
    end
  end
end
