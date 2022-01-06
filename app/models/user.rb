class User < ApplicationRecord
  VEHICLE_TYPE = [["Bike", false], ["Car", true]]
  EMPLOYEMENT_TYPE = [["Permanent", 'permanent'], ['Temporary', 'temporary']]
  GENDER = [["Male", 'Male'], ['Female','female'], ['Others', 'others']]
  STATUS = [["Confirm",'confirm'],['Contract','contract'],['Probation','probation'],['Trainee','trainee']]
  PAYMENT_MODE = [['Cash','cash'],['Bank Transfer','bank transfer'],['Cheque','cheque'],['Demand Draft','demand draft']]
  ROLES = [['Transporter', 'transporter'], ['Kitchen Manager', 'kitchen_manager'], ['Manager', 'manager']]
  APPROVAL_STATUS = {'pending': 'pending', 'approved': 'approved', 'rejected': 'rejected'}

  belongs_to  :role, optional: true
  belongs_to :country, optional: true
  belongs_to :delivery_company, optional: true
  has_one :user_detail, :dependent => :destroy, as: :detailable
  has_one :family_detail
  has_one :asset
  has_one :enterprise
  accepts_nested_attributes_for :user_detail, reject_if: :all_blank, allow_destroy: true
  has_one :employee_payment_detail, :dependent => :destroy
  accepts_nested_attributes_for :employee_payment_detail, reject_if: :all_blank, allow_destroy: true
  

  has_one  :cart, dependent: :destroy
  has_one :influencer_bank_detail, dependent: :destroy

  has_many :transporter_timings, dependent: :destroy
  # has_many :banks, dependent: :destroy
  # has_many :card_types, dependent: :destroy
  has_many :auths, dependent: :destroy
  has_many :vendors, dependent: :destroy
  has_many :social_auths, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :restaurants, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :order_transporters, class_name: "Order", foreign_key: "transporter_id"
  has_many :branch_managers, :dependent => :delete_all
  has_many :manager_branches, through: :branch_managers, source: :branch
  has_many :branch_transports, dependent: :destroy
  has_many :branches, through: :branch_transports, source: :branch
  has_many :branch_kitchen_managers, dependent: :destroy
  has_many :kitchen_managers, through: :branch_kitchen_managers, source: :branch
  has_many :points, dependent: :destroy
  has_many :redeem_points, dependent: :destroy
  has_many :referrals, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :ious, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :received_notifications, class_name: "Notification", foreign_key: "receiver_id", dependent: :destroy
  has_many :ious_transporters, class_name: "Iou", foreign_key: "transporter_id", dependent: :destroy
  has_many :user_clubs, dependent: :destroy
  has_many :club_sub_categories, through: :user_clubs
  has_many :order_reviews
  has_many :influencer_contracts, dependent: :destroy
  has_many :suggest_restaurants, dependent: :destroy
  has_many :influencer_payments, dependent: :destroy
  has_many :order_requests, dependent: :destroy
  has_many :influencer_coupons, dependent: :destroy
  has_many :referral_coupon_users, dependent: :destroy
  has_many :restaurant_coupon_users, dependent: :destroy
  has_many :pos_checks, dependent: :destroy
  has_many :created_order_types, class_name: 'OrderType', foreign_key: :created_by_id, dependent: :destroy
  has_many :updated_order_types, class_name: 'OrderType', foreign_key: :last_updated_by_id, dependent: :destroy

  has_many :created_payment_methods, class_name: 'PaymentMethod', foreign_key: :created_by_id, dependent: :destroy
  has_many :updated_payment_methods, class_name: 'PaymentMethod', foreign_key: :last_updated_by_id, dependent: :destroy
  has_one :driver, class_name: 'PosCheck', foreign_key: :driver_id, dependent: :destroy

  has_and_belongs_to_many :zones
  has_and_belongs_to_many :delivery_company_shifts

  validates :email, presence: true, uniqueness: { scope: :email }
  validates :user_name, presence: true, uniqueness: { scope: :user_name }, if: :perform_validation?

  before_save :downcase_user_stuff

  scope :busy_drivers, -> { joins(:order_transporters).where(status: true, orders: { is_delivered: false, pickedup: true, is_cancelled: false }).reject_ghost_driver }
  scope :idle_drivers, -> { where(status: true, busy: false).where.not(latitude: nil, longitude: nil).reject_ghost_driver }
  scope :offline_drivers, -> { where("status = ? OR latitude is null OR longitude is null", false).reject_ghost_driver }
  scope :reject_ghost_driver, -> { where.not(name: "Food Club Driver", email: "dineintransporter@foodclube.com")  }
  scope :available_drivers, -> { where(status: true).where.not(latitude: nil, longitude: nil) }
  scope :not_available_drivers, -> { where(status: true, busy: false) }
  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }
  scope :filter_by_role, ->(role_id) { where(role_id: role_id) }
  scope :search_by_keyword, ->(keyword) { where("name LIKE ? OR email = ?", "%#{keyword}%", keyword) }
  scope :influencer_users, -> { where(influencer: true) }
  scope :non_influencer_users, -> { where(influencer: false) }
  scope :order_by_id_desc, -> { order("users.id DESC") }

  def as_json(options = {})
    @order = options[:order]
    super(options.merge(except: [:created_at, :updated_at], methods: [:amount, :is_assigned]))
  end

  def ghost_driver?
    name == "Food Club Driver"
  end

  def self.restaurant_suggestion_list_csv(restaurant, area)
    CSV.generate do |csv|
      header = "Suggested Restaurants Users List for " + restaurant + " in " + area
      csv << [header]

      second_row = ["Name", "Email", "Contact"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.name
        @row << user.email
        @row << (user.contact.present? ? (user.country_code.to_s + user.contact.to_s) : "NA")
        csv << @row
      end
    end
  end

  def self.create_user(name, role, email, user_name, country_code, contact, image, cpr_number, country_id, vehicle_type=nil, dob=nil, cpr_number_expiry=nil, gender=nil, status=nil, user=nil)
    @role = role
    user = new(name: name, email: email, user_name: user_name, country_code: country_code, contact: contact, image: image, cpr_number: cpr_number, country_id: country_id, vehicle_type: vehicle_type, dob: dob, cpr_number_expiry: cpr_number_expiry, gender: gender, status: status)
    user.save!
    !user.id.nil? ? { code: 200, result: user } : { code: 400, result: user.errors.full_messages.join(", ") }
  end

  def update_user(name, role, email, user_name, country_code, contact, image, cpr_number, country_id, vehicle_type, dob, cpr_number_expiry, gender, status)
    @role = role
    self.update(name: name, email: email, user_name: user_name, country_code: country_code, contact: contact, image: image, cpr_number: cpr_number, country_id: country_id, vehicle_type: vehicle_type,dob: dob, cpr_number_expiry:cpr_number_expiry, gender: gender, status: status)
    !self.id.nil? ? { code: 200, result: self } : { code: 400, result: self.errors.full_messages.join(", ") }
  end

  def self.update_token(user, role)
    ltoken = format("%04d", Random.rand(1000..9999))
    stoken = format("%06d", Random.rand(100_000..999_999))
    auth = user.auths.find_by(role: role)
    auth.update(otp: ltoken, reset_password_token: "#{stoken}t#{user.id}u#{(Time.now.to_i * 379).to_s.reverse}#{ltoken}", reset_password_sent_at: Time.now)
    auth
  end

  def self.update_user_profile(user, name, country_code, contact, image)
    updated = user.update(name: name, country_code: country_code, contact: contact, image: image)
    updated ? { code: 200, result: user } : { code: 400, result: user.errors.full_messages.join(", ") }
  end

  def self.get_user(user_id)
    find_by(id: user_id)
  end

  def amount
    amount = 0
    ious_transporters.where("(DATE(updated_at) > ? and DATE(updated_at) <= ?)", Date.today - 3, Date.today).find_each do |amt|
      iouAmount = amt.is_received == false ? amt.paid_amount.to_f : 0
      amount = amount.to_f + iouAmount.to_f
    end
    amount.to_f
  end

  def is_assigned
    order_transporters.exists?(@order)
  end

  def self.edit_device_token(device_token, device_type, access_token, user)
    token = user.auths.first.server_sessions.find_by(server_token: access_token)
    token.session_device ? token.session_device.update(device_type: device_type, device_id: device_token) : SessionDevice.create(device_type: device_type, device_id: device_token, session_token: token.server_token, server_session_id: token.id)
  end

  def self.create_restaurant_owner(req_restaurant)
    user = new(name: req_restaurant.owner_name, email: req_restaurant.email, contact: req_restaurant.contact_number, country_id: req_restaurant.country_id, is_approved: 1)
    user.save!
    !user.id.nil? ? { code: 200, result: user } : { code: 400, result: user.errors.full_messages.join(", ") }
  end

  def self.create_restaurant_owner_by_admin(name, email, full_phone)
    user = new(name: name, email: email, contact: full_phone)
    user.save!
    !user.id.nil? ? { code: 200, result: user } : { code: 400, result: user.errors.full_messages.join(", ") }
  end

  def self.create_delivery_company_person(company)
    user = new(name: company.name, email: company.email, contact: company.contact_no, delivery_company_id: company.id)
    user.save!
    !user.id.nil? ? { code: 200, result: user } : { code: 400, result: user.errors.full_messages.join(", ") }
  end

  def auth_role
    auths.where("role = ? or role = ? or role = ? or role = ?", "business", "manager", "kitchen_manager", "delivery_company").first&.role
  end

  def check_role?(role_name)
    role.privileges.any? { |r| r.privilege_name == role_name }
  end

  def get_country_name
    if auths.first&.role == "business"
      restaurants.first&.country&.name
    elsif auths.first&.role == "manager"
      branch_managers.first&.branch&.restaurant&.country&.name
    elsif auths.first&.role == "kitchen_manager"
      branch_kitchen_managers.first&.branch&.restaurant&.country&.name
    elsif auths.first&.role == "delivery_company"
      delivery_company.country.name
    end
  end

  def can_free_driver(order)
    busy && !ghost_driver? && (order.created_at.to_date != Date.today) && order_transporters.where("date(created_at) = ?", Date.today).blank?
  end

  def total_available_points
    (points.credited.sum(:user_point) - points.debited.sum(:user_point)).to_f.round(3)
  end

  def self.filter_users(keyword, country_id, role_id, start_date, end_date)
    users = all
    users = users.filter_by_country(country_id) if country_id.present?
    users = users.filter_by_role(role_id) if role_id.present?
    users = users.search_by_keyword(keyword) if keyword.present?
    users = users.where("DATE(created_at) >= ?", start_date.to_date) if start_date.present?
    users = users.where("DATE(created_at) <= ?", end_date.to_date) if end_date.present?
    users
  end

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_initialize do |user|
      user.name = auth.info.name
      user.email = auth.info.email
    end
  end

  def other_shift_timings(day)
    timings = []

    delivery_company_shifts.where(day: day).order(:start_time).each do |shift|
      timings << [shift.start_time + "-" + shift.end_time]
    end

    timings.join("; ")
  end

  def average_order_delivery_time(orders)
    total = 0
    delivered_orders = orders.select { |o| o.is_delivered == true }

    if delivered_orders.present?
      delivered_orders.each do |o|
        total += (o.delivered_at - o.pickedup_at).to_i if o.delivered_at && o.pickedup_at
      end

      ((total / delivered_orders.size.to_f) / 60.to_f).round
    else
      0
    end
  end

  def average_order_accept_time(orders)
    total = 0
    count = 0

    if orders.present?
      orders.each do |o|
        total += (o.driver_accepted_at - o.driver_assigned_at).to_i if o.driver_accepted_at && o.driver_assigned_at
        count += 1
      end

      ((total / count.to_f) / 60.to_f).round
    else
      0
    end
  end

  def busy_time(orders)
    total_time = 0

    orders.each do |o|
      if o.cancelled_at && o.driver_assigned_at
        total_time += (o.cancelled_at - o.driver_assigned_at).to_i
      elsif o.delivered_at && o.driver_assigned_at
        total_time += (o.delivered_at - o.driver_assigned_at).to_i
      end
    end

    total_time
  end

  def self.admin_driver_list_csv
    CSV.generate do |csv|
      header = "Drivers List"
      csv << [header]
      second_row = ["Id", "Name", "CPR no", "Delivery Company", "Restaurant", "Zones"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.cpr_number
        @row << user.delivery_company&.name
        @row << user.branches.first&.restaurant&.title
        @row << (user.zones.pluck(:name).sort.join(", ").presence || "All")
        csv << @row
      end
    end
  end

  def self.user_list_csv(role)
    CSV.generate do |csv|
      header = "All " + role.to_s
      csv << [header]

      second_row = ["Name", "User name", "Email", "Contact", "Joined On", "Country"]

      if role.to_s == "transporter"
        second_row << ["State", "Company", "Restaurant"]
      elsif role.to_s == "customer"
        second_row << ["Referred by"]
      end

      csv << second_row.flatten

      all.each do |user|
        @row = []
        @row << user.name
        @row << (user.user_name.presence || "N/A")
        @row << user.email
        @row << (user.contact.presence || "NA")
        @row << user.created_at.strftime("%d/%m/%Y")
        @row << (user.country&.name.presence || "NA")

        if role.to_s == "transporter"
          @row << (user.delivery_company&.state&.name || "NA")
          @row << (user.delivery_company&.name.presence || "NA")
          @row << (user.branches.first&.restaurant&.title.presence || "NA")
        end

        if role.to_s == "customer"
          referred_by = Referral.find_by(email: user.email)&.user
          @row << (referred_by ? referred_by.name + " (" + referred_by.email + ")" : "")
        end

        csv << @row
      end
    end
  end

  def self.transporters_list_csv
    CSV.generate do |csv|
      header = "Transporters List"
      csv << [header]

      second_row = ["User Id", "User Name", "Cpr Number", "Contact", "Zones", "Vehicle Type"]
      csv << second_row

      all.order(:id).each do |transporter|
        @row = []
        @row << transporter.id
        @row << transporter.name
        @row << transporter.cpr_number
        @row << transporter.country_code + transporter.contact
        @row << zones = transporter.zones.pluck(:name).sort.join(", ").presence || "All"
        @row << (transporter.vehicle_type.nil? ? "" : (transporter.vehicle_type ? "Car" : "Bike"))
        csv << @row
      end
    end
  end

  def self.admin_driver_performance_report_csv(start_date, end_date)
    CSV.generate do |csv|
      header = "Driver Performance Report"
      csv << [header]
      csv << ["Start Date: " + start_date.strftime("%Y-%m-%d"), "End Date: " + end_date.strftime("%Y-%m-%d")]

      second_row = ["Id", "Name", "CPR no", "Delivery Company", "Restaurant", "Total Orders", "Total Delivered Orders", "Cancelled Deliveries", "Cancelled Due to Customer", "Cancelled after Pickup", "Delivery Time", "Order Accept Time", "Not Onway in 30 mins", "Shifts Present", "Late Shifts", "Late Shifts Rate", "Planned Hours", "Worked Hours", "Worked Hours Rate", "Break Time", "Busy Time", "Idle Time"]
      csv << second_row

      all.each do |user|
        user_orders = user.order_transporters.where("DATE(orders.created_at) >= ? AND DATE(orders.created_at) <= ?", start_date, end_date)
        timings = user.transporter_timings.where("DATE(transporter_timings.created_at) >= ? AND DATE(transporter_timings.created_at) <= ?", start_date, end_date)
        planned_time = timings.uniq { |t| t.created_at.to_date }.map(&:shift_duration).sum
        working_time = timings.map(&:session_duration).sum
        busy_time = user.busy_time(user_orders)

        @row = []
        @row << user.id
        @row << user.name
        @row << user.cpr_number
        @row << user.delivery_company&.name
        @row << user.branches.first&.restaurant&.title
        @row << user_orders.size
        @row << user_orders.select { |o| o.is_delivered == true }.size
        @row << user_orders.select { |o| o.is_cancelled == true }.size
        @row << user_orders.select { |o| o.is_cancelled == true && o.cancel_request_by == "Customer" }.size
        @row << user_orders.select { |o| o.is_cancelled == true && o.pickedup == true }.size
        @row << (user_orders.select { |o| o.is_delivered == true }.present? ? user.average_order_delivery_time(user_orders).to_s + " mins" : "NA")
        @row << (user_orders.select { |o| o.driver_accepted_at.present? }.present? ? user.average_order_accept_time(user_orders).to_s + " mins" : "NA")
        @row << user_orders.select { |o| o.pickedup_at && o.driver_accepted_at && ((o.pickedup_at - o.driver_accepted_at).to_i > 1800) }.size
        @row << (total_shifts = timings.map(&:shifts_done).uniq.count)
        @row << (late_shifts = timings.map(&:late_shifts).uniq.count)

        if user.delivery_company && total_shifts.positive?
          @row << (((late_shifts / total_shifts.to_f) * 100).to_f.round(2).to_s + "%")
        else
          @row << ""
        end

        @row << (user.delivery_company ? ApplicationController.helpers.time_duration(planned_time): "")
        @row << ApplicationController.helpers.time_duration(working_time)

        if user.delivery_company && planned_time.to_f.positive?
          @row << (((working_time / planned_time.to_f) * 100).to_f.round(2).to_s + "%")
        else
          @row << ""
        end

        @row << (user.delivery_company ? ApplicationController.helpers.time_duration(planned_time - working_time) : "")
        @row << ApplicationController.helpers.time_duration(busy_time)
        @row << ApplicationController.helpers.time_duration(working_time - busy_time)
        csv << @row
      end
    end
  end

  def point_list_csv(points, referrals)
    CSV.generate do |csv|
      header = name + " Points and Referrals"
      csv << [header]

      if points[:point].present?
        csv << [""]
        csv << ["POINTS DETAILS"]
        csv << ["TOTAL POINTS: " + points[:totalPoint].to_s]
        csv << ["Restaurant", "Branch", "Points"]

        points[:point].each do |point|
          @row = []
          @row << point["branch"]["restaurant_name"]
          @row << point["branch"]["address"]
          @row << point["user_point"].to_f.round(3)
          csv << @row
        end
      end

      if referrals.present?
        csv << [""]
        csv << ["REFERRALS"]
        csv << ["Sl No", "Name", "Email", "Joined"]

        referrals.each_with_index do |referral, i|
          user = User.find_by(email: referral.email)

          @row = []
          @row << (i + 1)
          @row << user.name
          @row << user.email
          @row << user.created_at.strftime("%d/%m/%Y")
          csv << @row
        end
      end
    end
  end

  def self.role_user_list_csv
    CSV.generate do |csv|
      header = "Role Based User List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Role", "Country", "Approval status", "Reject Reason", "Joined On", "Approved/Rejected On"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.email
        @row << user.country_code.to_s + "-" + user.contact.to_s
        @row << user.role&.role_name
        @row << user.country&.name
        @row << (user.is_rejected == 1 ? "Rejected" : "Approved")
        @row << (user.is_rejected == 1 ? user.reject_reason : "N/A")
        @row << (user.created_at.strftime("%d/%m/%Y"))
        @row << (user.approved_at&.strftime("%d/%m/%Y") || user.rejected_at&.strftime("%d/%m/%Y"))
        csv << @row
      end
    end
  end

  def self.unapproved_user_list_csv
    CSV.generate do |csv|
      header = "Unapproved Role Based User List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Role", "Country", "Reject Reason", "Requested On"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.email
        @row << user.country_code.to_s + "-" + user.contact.to_s
        @row << user.role&.role_name
        @row << user.country&.name
        @row << (user.is_rejected == 1 ? user.reject_reason : "N/A")
        @row << (user.created_at.strftime("%d/%m/%Y"))
        csv << @row
      end
    end
  end

  def self.influencer_list_csv
    CSV.generate do |csv|
      header = "Influencer List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Country", "Joined On", "Approved On"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.email
        @row << user.country_code.to_s + "-" + user.contact.to_s
        @row << user.country&.name
        @row << user.created_at.strftime("%d/%m/%Y")
        @row << user.approved_at&.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.requested_influencer_list_csv
    CSV.generate do |csv|
      header = "Requested Influencer List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Country", "Requested On"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.email
        @row << user.country_code.to_s + "-" + user.contact.to_s
        @row << user.country&.name
        @row << user.created_at.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.rejected_influencer_list_csv
    CSV.generate do |csv|
      header = "Rejected Influencer List"
      csv << [header]

      second_row = ["ID", "Name", "Email", "Contact No", "Country", "Reject Reason", "Rejected On"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.id
        @row << user.name
        @row << user.email
        @row << user.country_code.to_s + "-" + user.contact.to_s
        @row << user.country&.name
        @row << user.reject_reason
        @row << user.rejected_at&.strftime("%d/%m/%Y")
        csv << @row
      end
    end
  end

  def self.club_user_list_csv(club_category)
    CSV.generate do |csv|
      header = "Club Users in #{club_category.title}"
      csv << [header]

      second_row = ["Name", "Username", "Email", "Contact", "#{club_category.class.name == "ClubSubCategory" ? "Joined" : ""}"]
      csv << second_row

      all.each do |user|
        @row = []
        @row << user.name
        @row << (user.user_name.presence || "NA")
        @row << user.email
        @row << (user.contact.presence || "NA")

        if club_category.class.name == "ClubSubCategory"
          @row << user.user_clubs.select { |uc| uc.club_sub_category_id == club_category.id }.first&.created_at&.strftime("%d/%m/%Y")
        end

        csv << @row
      end
    end
  end

  private

  def perform_validation?
    @role.present? ? auths.first&.role == "customer" : @role
  end

  def downcase_user_stuff
    self.name = name.titleize rescue nil
    self.email = email.downcase rescue nil

    if country_id.nil?
      c_id = if auths.first&.role == "business"
               restaurants.first&.country_id
             elsif auths.first&.role == "manager"
               branch_managers.first&.branch&.restaurant&.country_id
             elsif auths.first&.role == "kitchen_manager"
               branch_kitchen_managers.first&.branch&.restaurant&.country_id
             elsif auths.first&.role == "delivery_company"
               delivery_company&.country_id
             elsif auths.first&.role == "transporter" && delivery_company_id.present?
               delivery_company&.country_id
             elsif auths.first&.role == "transporter" && delivery_company_id.nil?
               branch_transports.first&.branch&.restaurant&.country_id
             end

      self.country_id = c_id
    end
  end
end
