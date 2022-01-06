class ReferralCoupon < ApplicationRecord
  belongs_to :country

  has_many :referral_coupon_branches, dependent: :destroy
  has_many :referral_coupon_menu_items, dependent: :destroy

  has_many :branches, through: :referral_coupon_branches
  has_many :menu_items, through: :referral_coupon_menu_items
  has_many :referral_coupon_users, dependent: :destroy

  validates :referrer_discount, :referrer_quantity, :total_referrer_quantity, :referred_discount, :referred_quantity, :total_referred_quantity, presence: true
  validates :coupon_code, presence: true, uniqueness: true
  validate :date_validation, :code_validation

  scope :active, -> { where(active: true) }
  scope :order_by_date, -> { order(start_date: :desc) }

  def self.filter_by_keyword(country_id, keyword, start_date, end_date)
    coupons = all
    coupons = coupons.where(country_id: country_id) if country_id.present?
    coupons = coupons.joins(branches: :restaurant).where("coupon_code like ? OR restaurants.title like ?", "%#{keyword}%", "%#{keyword}%") if keyword.present?
    coupons = coupons.where("DATE(referral_coupons.start_date) <= ? AND DATE(referral_coupons.end_date) >= ?", start_date.to_date, start_date.to_date) if start_date.present?
    coupons = coupons.where("DATE(referral_coupons.start_date) <= ? AND DATE(referral_coupons.end_date) >= ?", end_date.to_date, end_date.to_date) if end_date.present?
    coupons
  end

  def referrer_quantity_used
    total_referrer_quantity - referrer_quantity
  end

  def referred_quantity_used
    total_referred_quantity - referred_quantity
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

  def self.referral_coupon_list_csv(country_id, start_date, end_date)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "Referral Coupons List"
      csv << [header]

      csv << ["Country: " + country_name, "Start Date: " + start_date, "End Date: " + end_date]
      second_row = ["Coupon Code", "Discount (%) (Referrer)", "Discount (%) (Referred)", "Total Quantity (Referrer)", "Quantity Left (Referrer)", "Total Quantity (Referred)", "Quantity Left (Referred)", "Start Date", "End Date", "Country", "Status", "Notes", "Restaurants"]
      csv << second_row

      all.order_by_date.each do |coupon|
        @row = []
        @row << coupon.coupon_code
        @row << coupon.referrer_discount
        @row << coupon.referred_discount
        @row << coupon.total_referrer_quantity
        @row << coupon.referrer_quantity
        @row << coupon.total_referred_quantity
        @row << coupon.referred_quantity
        @row << coupon.start_date.strftime("%d/%m/%Y")
        @row << coupon.end_date.strftime("%d/%m/%Y")
        @row << coupon.country&.name
        @row << coupon.current_status
        @row << coupon.notes
        @row << (coupon.branches.map(&:restaurant).map(&:title).flatten.uniq.sort.join(" | ").presence || "All Restaurants")
        csv << @row
      end
    end
  end

  private

  def date_validation
    new_range = self[:start_date]..self[:end_date]
    @overlap = false

    ReferralCoupon.where.not(id: id).find_each do |c|
      range = c.start_date..c.end_date

      if new_range.overlaps?(range)
        @overlap = true
        break
      end
    end

    if self[:start_date] >= self[:end_date]
      errors.add(:base, "End Date should be greater than Start Date")
    elsif @overlap
      errors.add(:base, "Referral Coupon already present for this Date Range")
    end
  end

  def code_validation
    existing_influencer_coupon = InfluencerCoupon.where(coupon_code: self[:coupon_code])
    existing_restaurant_coupon = RestaurantCoupon.where(coupon_code: self[:coupon_code])

    if existing_influencer_coupon.present?
      errors.add(:base, "This Coupon Code is already in use as Influencer Coupon")
    elsif existing_restaurant_coupon.present?
      errors.add(:base, "This Coupon Code is already in use as Restaurant Coupon")
    end
  end
end
