class Order < ApplicationRecord
  ORDER_TYPE = [["Online", "prepaid"], ["Cash on Delivery", "postpaid"], ["Credit Card Machine", "card_machine"]]
  PAYMENT_OPTIONS = [["Cash", "postpaid"], ["Online", "prepaid"], ["Credit Card Machine", "card_machine"]]
  DELIVERY_COMPANY_ORDER_TYPE = [["Online", "prepaid"], ["Cash", "postpaid"]]
  DELIVERY_TYPE = [["Restaurant", false], ["Food Club", true]]
  STATUSES = ["INITIALIZE", "ORDER ACCEPTED", "COOKING", "ONWAY", "DELIVERED", "SETTLED", "ORDER REJECTED", "CANCELLED"]
  DELIVERY_COMPANY_STATUSES = ["ORDER ACCEPTED", "COOKING", "ONWAY", "DELIVERED", "SETTLED", "CANCELLED"]

  belongs_to :branch
  belongs_to :user
  belongs_to :transporter, class_name: "User", foreign_key: "transporter_id", optional: true
  belongs_to :coverage_area, optional: true
  belongs_to :pos_check, optional: true
  has_one :redeem_point, dependent: :destroy
  has_one :order_review, dependent: :destroy
  has_one :rating, dependent: :destroy
  has_one :iou, dependent: :destroy
  has_one :order_incident, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :menu_items, through: :order_items
  has_many :points, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :order_drivers, dependent: :destroy
  has_many :order_taxes, dependent: :destroy

  after_create :generate_order_qr
  before_save :assign_country_to_user, on: :create

  scope :delivered, -> { where(is_delivered: true) }
  scope :settled, -> { where(is_settled: true) }
  scope :rejected, -> { where(is_rejected: true) }
  scope :cancelled, -> { where(is_cancelled: true) }
  scope :dine_in_orders, -> { where(dine_in: true) }
  scope :delivery_orders, -> { where(dine_in: false) }
  scope :cancelled_by_customer, -> { where(is_cancelled: true, cancel_request_by: "Customer") }
  scope :cancelled_after_pickup, -> { where(is_cancelled: true, pickedup: true) }
  scope :accepted_by_driver, -> { where.not(driver_accepted_at: nil) }
  scope :online_orders, -> { where(order_type: "prepaid") }
  scope :cash_orders, -> { where(order_type: "postpaid") }
  scope :credit_card_machine_orders, -> { where(order_type: "card_machine") }
  scope :order_by_date_desc, -> { order("orders.created_at DESC") }
  scope :include_related_tables, -> { includes(:user, :transporter, branch: :restaurant) }
  scope :filter_by_date, ->(date) { where("date(orders.created_at) = ?", (date.presence || Date.today)) }
  scope :returned_orders, -> { where(is_cancelled: true, refund_fault: "Driver") }
  scope :disputed_orders, -> { where("orders.is_cancelled = true AND orders.refund_fault = ? AND ((orders.order_type = ? AND orders.refund = false) OR (orders.order_type = ? AND orders.refund = true))", "Brand", "postpaid", "prepaid") }
  scope :pending_settled_orders, -> { where("(orders.is_delivered = true AND orders.order_type = ?) OR ((orders.is_cancelled = true) && ((orders.order_type = ? AND orders.refund = false AND orders.refund_fault = ?) OR (orders.order_type = ? AND orders.refund = false AND orders.refund_fault = ?) OR (orders.order_type = ? AND orders.refund = true AND orders.refund_fault = ?)))", "postpaid", "prepaid", "Customer", "postpaid", "Driver", "prepaid", "Driver") }
  scope :settle_amount_list, ->(transporter_ids, date) { include_related_tables.where(transporter_id: transporter_ids).pending_settled_orders.filter_by_date(date).order_by_date_desc }
  scope :settle_amount_list_report, ->(transporter_ids) { include_related_tables.where(transporter_id: transporter_ids).pending_settled_orders.order_by_date_desc }
  scope :pending_settle_list, ->(transporter_ids, date) { where(transporter_id: transporter_ids, payment_approved_at: nil, payment_approval_pending: false).where("date(created_at) < ?", (date.presence || Date.today)).pending_settled_orders }
  scope :admin_pending_settle_list, ->(transporter_ids, date) { where(transporter_id: transporter_ids, payment_approved_at: nil, payment_rejected_at: nil, payment_approval_pending: true).where("date(created_at) < ?", (date.presence || Date.today)).pending_settled_orders }
  scope :admin_settle_amount_list, ->(transporter_ids, start_date, end_date) { include_related_tables.where(transporter_id: transporter_ids, payment_approved_at: nil, payment_rejected_at: nil, payment_approval_pending: true).pending_settled_orders.filter_by_date_range(start_date, end_date).order_by_date_desc }
  scope :filter_by_date_range, ->(start_date, end_date) { where("date(orders.created_at) BETWEEN ? AND ?", (start_date.presence || Date.today), (end_date.presence || Date.today) ) }
  scope :prepaid_settle_order_list, -> (transporter_ids) { include_related_tables.where(transporter_id: transporter_ids, order_type: "prepaid") }

  # before_destroy :remove_points
  def as_json(options = {})
    @language = options[:language]
    super(options.merge(except: [:updated_at, :menu_item_id, :cart_id, :user_id, :transporter_id, :total_amount], methods: [:address, :total_amount, :currency_code_en, :currency_code_ar, :restaurant_logo, :restaurant_name, :driver_pending_acceptance, :iou_received, :food_club_number]))
  end

  def currency_code_en
    branch.restaurant.country.currency_code.to_s
  end

  def currency_code_ar
    branch.restaurant.country.currency_code.to_s
  end

  def restaurant_logo
    branch&.restaurant&.logo
  end

  def restaurant_name
    if @language == "arabic"
      branch.restaurant.title_ar.presence || branch.restaurant.title
    else
      branch.restaurant.title
    end
  end

  def driver_pending_acceptance
    delivered_at.nil? && driver_accepted_at.nil?
  end

  def iou_received
    iou.nil? || iou&.is_received == true
  end

  def food_club_number
    "16003600"
  end

  def total_credit_points
    points.select { |p| p.point_type == "Credit" }.map(&:user_point).sum.to_f
  end

  def total_debit_points
    points.select { |p| p.point_type == "Debit" }.map(&:user_point).sum.to_f
  end

  def late_delivered_order
    late = false

    if delivered_at.present?
      max_time = BranchCoverageArea.find_by(branch_id: branch_id, coverage_area_id: coverage_area_id)&.delivery_time
      actual_time = (delivered_at - created_at).to_i
      late = ((actual_time.to_i / 60) > max_time.to_i) if max_time.present?
    end

    late
  end

  def late_delivery_duration
    late_duration = 0

    if delivered_at.present?
      max_time = BranchCoverageArea.find_by(branch_id: branch_id, coverage_area_id: coverage_area_id)&.delivery_time
      actual_time = (delivered_at - created_at).to_i
      late = ((actual_time.to_i / 60) - max_time.to_i) if max_time.present?
    end

    late.to_i
  end

  def third_party_payable_amount
    third_party_delivery ? (total_amount.to_f + third_party_refund_charge).to_f.round(3) : 0
  end

  def third_party_total_amount
    third_party_delivery ? (total_amount.to_f - delivery_charge.to_f).to_f.round(3) : total_amount.to_f.round(3)
  end

  def business_third_party_delivery_charge
    if third_party_delivery && order_type == "postpaid"
      bca = BranchCoverageArea.find_by(branch_id: branch_id, coverage_area_id: coverage_area_id)

      if bca&.third_party_delivery_type == "Chargeable"
        charge = delivery_charge.to_f
      else
        if branch.latitude.present? && branch.longitude.present? && latitude.present? && longitude.present?
          dist = Geocoder::Calculations.distance_between([branch.latitude, branch.longitude], [latitude, longitude], units: :km).to_f.round(3)
          charge = get_delivery_charge_by_distance(dist, branch.restaurant.country_id)
        else
          charge = 0.0
        end
      end
    else
      charge = 0.0
    end

    charge
  end

  def business_third_party_delivery_charge_all
    if third_party_delivery
      bca = BranchCoverageArea.find_by(branch_id: branch_id, coverage_area_id: coverage_area_id)

      if bca&.third_party_delivery_type == "Chargeable" && changed_delivery == false
        charge = delivery_charge.to_f
      else
        if branch.latitude.present? && branch.longitude.present? && latitude.present? && longitude.present?
          dist = Geocoder::Calculations.distance_between([branch.latitude, branch.longitude], [latitude, longitude], units: :km).to_f.round(3)
          charge = get_delivery_charge_by_distance(dist, branch.restaurant.country_id)
        else
          charge = 0.0
        end
      end
    else
      charge = 0.0
    end

    charge
  end

  def business_food_club_charges
    if third_party_delivery && order_type == "postpaid"
      fixed_fc_charge_percentage = DeliveryCharge.find_by(country_id: branch.restaurant.country_id)&.delivery_percentage
      fc_charge = ((sub_total * fixed_fc_charge_percentage / 100.to_f) * 105/100.to_f)
    else
      fc_charge = 0
    end

    fc_charge
  end

  def business_food_club_charges_all
    if third_party_delivery
      fixed_fc_charge_percentage = DeliveryCharge.find_by(country_id: branch.restaurant.country_id)&.delivery_percentage
      fc_charge = ((sub_total * fixed_fc_charge_percentage / 100.to_f) * 105/100.to_f)
    else
      fc_charge = 0
    end

    fc_charge.to_f.round(3)
  end

  def third_party_payable_amount_business
    third_party_delivery ? (total_amount.to_f + third_party_refund_charge - business_third_party_delivery_charge - business_food_club_charges).to_f.round(3) : 0
  end

  def third_party_payable_amount_business_all
    third_party_delivery ? (total_amount.to_f + third_party_refund_charge_all - business_third_party_delivery_charge_all - business_food_club_charges_all - card_charge - fixed_fc_charge.to_f).to_f.round(3) : 0
  end

  def restaurant_payable_amount_business_all
    (total_amount.to_f - third_party_refund_charge_all - card_charge - fixed_fc_charge.to_f).to_f.round(3)
  end

  def third_party_refund_charge
    if order_type == "prepaid" && refund && refund_fault == "Driver"
      card_charge.to_f.round(3)
    else
      0
    end
  end

  def third_party_refund_charge_all
    if order_type == "prepaid" && refund
      card_charge.to_f.round(3)
    else
      0
    end
  end

  def card_charge
    if card_type == "Credit"
      (total_amount.to_f * 2.2/100.to_f)
    elsif card_type == "Debit"
      (total_amount.to_f * 1/100.to_f)
    else
      0
    end
  end

  def self.create_order(user, cart, transactionDetails, totalAmount, address, order_mode, note, is_redeem)
    order = new(fname: address.fname, lname: address.lname, note: note, area: address.coverage_area.area, street: address.street, address_type: address.address_type, block: address.block, building: address.building, floor: address.floor, apartment_number: address.apartment_number, additional_direction: address.additional_direction, contact: address.country_code.to_s + address.contact.to_s, landline: address.landline, latitude: address.latitude, longitude: address.longitude, transection_id: transactionDetails, total_amount: totalAmount[:total_price], sub_total: totalAmount[:sub_total], user_id: user.id, qr_image: "", branch_id: cart.branch_id, order_type: order_mode, payment_mode: order_mode == "prepaid" ? "online" : order_mode == "postpaid" ? "COD" : "CCM", pickedup: false, is_delivered: false, is_paid: (order_mode == "prepaid" || totalAmount[:total_price].to_f.zero?), is_ready: false, delivery_charge: totalAmount[:delivery_charges], tax_amount: totalAmount[:total_tax_amount], used_point: is_redeem == "true" ? totalAmount[:used_point] : 0.0, is_redeem: is_redeem == "true", coverage_area_id: cart.coverage_area_id, third_party_delivery: totalAmount[:fc_delivery], tax_percentage: totalAmount[:tax_percentage])

    order.save!
    !order.id.nil? ? { code: 200, result: order } : { code: 400, result: order.errors.full_messages.join(", ") }
    orderAddon = OrderItem.add_order_items(cart, order, totalAmount, is_redeem)
    Point.create_point(order, order.user.id, totalAmount[:used_point], "Debit") if is_redeem == "true" && (order.order_type == "postpaid" || (order.order_type == "prepaid" && order.points.debited.blank?))
    totalAmount[:taxes].each do |tax|
      order.order_taxes.create(name: tax["tax_name"], percentage: tax["tax_percentage"], amount: tax["tax_amount"])
    end

    order
  end

  def self.find_transaction(transaction_id)
    find_by(transection_id: transaction_id)
  end

  def total_amount
    format("%0.03f", self["total_amount"])
  end

  def distance
    if branch.latitude && branch.longitude && latitude && longitude
      Geocoder::Calculations.distance_between([branch.latitude, branch.longitude], [latitude, longitude], units: :km).to_f.round(3)
    end
  end

  def total_tax_amount
    order_taxes.present? ? order_taxes.sum(:amount).to_f.round(3) : tax_amount
  end

  def generate_order_qr
    AdminNewOrderWorker.perform_at(10.seconds.from_now, id)
    OrderNotificationWorker.perform_at(3.minutes.from_now, id)
    OrderNotificationWorker.perform_at(6.minutes.from_now, id)
    AdminOrderNotificationWorker.perform_at(8.minutes.from_now, id)
    self.qr_image = generateAndUploadQRcodeAtCloudinary(self, "order_qr_image")
    rescue Exception => e
  end

  def address
    area =  self.area.presence || ""
    block = self.block.presence || ""
    street = self.street.presence || ""
    building = self.building.presence || ""
    floor = self.floor.presence || ""
    contact = self.contact.presence || ""
    address_type = self.address_type.presence || ""
    apartment_number = self.apartment_number.presence || ""
    additional_direction = self.additional_direction.presence || ""
    address = area + " " + address_type + " " + block + " " + street + " " + building + " " + floor + " " + apartment_number + " " + additional_direction + "" + contact
    address.strip
  end

  def generateAndUploadQRcodeAtCloudinary(qrcodeData, folderName)
    order = qrcodeData.id.to_s
    qrcode = RQRCode::QRCode.new(order)
    png = qrcode.as_png(resize_gte_to: false, resize_exactly_to: true, fill: "white", color: "black", size: 480, border_modules: 2, module_px_size: 6, file: nil)
    file = png.save("tmp/#{order}.png")
    uploader = Cloudinary::Uploader.upload("tmp/#{order}.png", use_filename: true, folder: folderName)
    File.delete(file)
    p uploader["secure_url"]
    qrcodeData.update(qr_image: uploader["secure_url"])
    qrcodeData.qr_image
  end

  def self.find_order_list(user, page, per_page)
    where(user_id: user.id, is_cancelled: false).order(id: "DESC").paginate(page: page, per_page: per_page)
  end

  def self.get_order(order_id, _user)
    find_by(id: order_id)
  end

  def business_transferrable_amount
    transferrable_amount.presence || third_party_payable_amount_business_all
  end

  def self.get_transporter_order(order_id, user)
    find_by(id: order_id, transporter_id: user.id)
  end

  def self.get_order_id(order_id, user)
    find_by(id: order_id, user_id: user.id)
  end

  def self.find_business_orders(order_id, branch_id)
    find_by(id: order_id, branch_id: branch_id)
  end

  def self.get_transporter_order_status(order_id, user)
    find_by(id: order_id, transporter_id: user.id, pickedup: true)
  end

  def self.find_business_orders_list(branch, keyword, page, per_page)
    case keyword
    when "today"
      orders = where("branch_id = (?) and is_rejected = (?) and DATE(created_at) = (?) and is_settled = ?", branch.id, false, Date.today, false).order(updated_at: "DESC").paginate(page: page, per_page: per_page)
    when "completed"
      orders = where(branch_id: branch.id, is_rejected: false, is_accepted: true, is_delivered: true, is_paid: true, is_settled: true).order(id: "DESC").paginate(page: page, per_page: per_page)
    else
      orders = where(branch_id: branch.id).order(id: "DESC").paginate(page: page, per_page: per_page)
     end
  end

  def self.check_order_date(date, branch_id)
    where("Date(created_at) = ? and branch_id = ?", date, branch_id)
  end

  def self.find_order_details(order_id)
    find(order_id)
  end

  def self.find_orders_list(transp_id)
    where(transporter_id: transp_id, is_accepted: true, is_ready: false, is_delivered: false)
  end

  def self.order_accept
    where("is_accepted=?", true)
  end

  def self.order_reject
    where("is_rejected=?", true)
  end

  def meal_type
    if created_at.hour >= 9 && created_at.hour < 12
      "Breakfast"
    elsif created_at.hour >= 12 && created_at.hour < 18
      "Lunch"
    else
      "Dinner"
    end
  end

  def cancel_request_by
    if self[:cancel_request_by].present?
      self[:cancel_request_by]
    else
      user = User.find_by(id: order_incident&.reported_by)

      if user.present?
        user.name.to_s + " (" + user.auths.first&.role.to_s.titleize + ")"
      end
    end
  end

  def cancellation_reason
    self[:cancellation_reason].presence || order_incident&.complaint_description
  end

  #==================================Define Scope=================================================
  scope :last_month_completed_order, -> { where("is_rejected = ? AND created_at > ? and created_at < ?", false, Date.today.last_month.beginning_of_month, Date.today.beginning_of_month) }
  scope :current_month_completed_order, -> { where("is_rejected = ? and created_at BETWEEN ? AND ? ", false, Time.now.beginning_of_month, Time.now.end_of_month) }

  def self.get_current_week_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_week, Date.today.end_of_week, branch, true)
  end

  def self.get_perivious_week_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_week - 7, Date.today.end_of_week - 7, branch, true)
  end

  def self.get_current_month_cancel_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_month, Date.today.end_of_month, branch, true)
  end

  def self.get_perivious_month_cancel_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_month - 1.month, Date.today.end_of_month - 1.month, branch, true)
  end

  def self.get_current_year_cancel_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_year, Date.today.end_of_year, branch, true)
  end

  def self.get_perivious_year_cancel_order(branch)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", Date.today.beginning_of_year - 1.year, Date.today.end_of_year - 1.year, branch, true)
  end

  def self.get_current_month_order(branch, todayDate)
    today = joins(:branch).where("DATE(orders.created_at) = ? and branches.id = (?) and is_rejected = (?)", todayDate, branch, false)
    yesterday = joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", todayDate - 1.day, branch, false)
    week1 = branch_order_data(branch, startdate - 2.days)
    week2 = branch_order_data(branch, startdate - 9.days)
    week3 = branch_order_data(branch, startdate - 16.days)
    week4 = branch_order_data(branch, startdate - 23.days)
    @result = {}
    [today, yesterday, week1, week2, week3, week4].flatten.each_with_index do |totalAmount, index|
      @result[(startdate - index.days).strftime("%Y-%m-%d").to_s] = totalAmount.round(2)
    end
    @result
    # joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)",todayDate.beginning_of_month,todayDate.end_of_month,branch,false)
  end

  def self.get_last_year_month_order(branch, todayDate)
    joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)", (todayDate - 12.months).beginning_of_month, (todayDate - 12.months).end_of_month, branch, false)
  end

  def branch_order_data(branch, startdate)
    today = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate, branch, false).sum(:total_amount).round(2)
    yesterday = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 1.day, branch, false).sum(:total_amount).round(2)
    before3days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 2.days, branch, false).sum(:total_amount).round(2)
    before4days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 3.days, branch, false).sum(:total_amount).round(2)
    before5days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 4.days, branch, false).sum(:total_amount).round(2)
    before6days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 5.days, branch, false).sum(:total_amount).round(2)
    before7days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 6.days, branch, false).sum(:total_amount).round(2)
  end

  def current_status
    is_cancelled == true ? "CANCELLED" : is_settled == true ? "SETTLED" : is_delivered == true ? "DELIVERED" : pickedup == true ? "ONWAY" : is_ready == true ? "COOKING" : is_accepted == true ? "ORDER ACCEPTED" : is_rejected == true ? "ORDER REJECTED" : "INITIALIZE"
  end

  def customer_order_status
    is_cancelled == true ? "CANCELLED" : is_delivered == true ? "DELIVERED" : pickedup == true ? "ONWAY" : is_ready == true ? "COOKING" : is_accepted == true ? "ORDER ACCEPTED" : is_rejected == true ? "ORDER REJECTED" : "INITIALIZE"
  end

  def self.delivery_settle_amount_report_csv(country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"

    CSV.generate do |csv|
      header = "Delivery Settle Amount Report"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Country: " + country_name]

      second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Service Charge (#{currency})", "Refund Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.restaurant&.title.presence || "NA"
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.third_party_total_amount)
        @row << format("%0.03f", order.delivery_charge)
        @row << format("%0.03f", order.third_party_refund_charge)
        @row << format("%0.03f", order.third_party_payable_amount)
        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.transporter.name
        csv << @row
      end

      csv << ["TOTAL", "", "", "", "", "", format("%0.03f", all.map(&:third_party_total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:delivery_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_payable_amount).map(&:to_f).sum.to_f)]

      csv << ["Total Orders", all.size]
      csv << ["Total Payable Amount", format("%0.03f", all.reload.map(&:third_party_payable_amount).map(&:to_f).sum) + " " + currency]
    end
  end

  def self.restaurant_settle_amount_report_csv(type, country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"

    CSV.generate do |csv|
      header = "Restaurant Settle Amount Report (#{type.titleize})"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Country: " + country_name]

      if type == "cash"
        second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "Delivery Charge (#{currency})", "FC Delivery Charge (#{currency})", "FC Fixed Charge (#{currency})", "Card Charge (#{currency})", "Payable Amount (#{currency})", "Transferrable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Status", "Comments"]
      else
        second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "Delivery Charge (#{currency})", "FC Delivery Charge (#{currency})", "FC Fixed Charge (#{currency})", "Card Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.restaurant&.title.presence || "NA"
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << format("%0.03f", order.third_party_refund_charge_all)
        @row << format("%0.03f", order.business_third_party_delivery_charge_all)
        @row << format("%0.03f", order.business_food_club_charges_all)
        @row << format("%0.03f", order.fixed_fc_charge.to_f)
        @row << format("%0.03f", order.card_charge)
        @row << format("%0.03f", order.third_party_payable_amount_business_all)

        if type == "cash"
          @row << (order.transferrable_amount ? format("%0.03f", order.transferrable_amount) : "")
        end

        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.transporter.name

        if type == "cash"
          @row << (order.paid_by_admin ? "PAID on #{order.paid_by_admin_at&.strftime('%d/%m/%Y at %I:%M %p')}" : "Not Paid")
        end

        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      csv << ["TOTAL", "", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_third_party_delivery_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_food_club_charges_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:card_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_payable_amount_business_all).map(&:to_f).sum.to_f), (type == "cash" ? format("%0.03f", all.sum(:transferrable_amount).to_f) : "")]

      csv << ["Total Orders", all.size]
      csv << ["Total Payable Amount", format("%0.03f", all.reload.map(&:third_party_payable_amount_business_all).map(&:to_f).sum) + " " + currency]
    end
  end

  def self.business_settle_amount_report_csv(type)
    CSV.generate do |csv|
      header = "Restaurant Settle Amount Report (#{type.titleize})"
      currency = all.first&.currency_code_en.to_s
      csv << [header]

      if type == "cash"
        second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "Delivery Charge (#{currency})", "FC Delivery Charge (#{currency})", "FC Fixed Charge (#{currency})", "Payable Amount (#{currency})", "Transferrable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Status", "Comments"]
      else
        second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "Delivery Charge (#{currency})", "FC Delivery Charge (#{currency})", "FC Fixed Charge (#{currency})", "Card Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << format("%0.03f", order.third_party_refund_charge_all)
        @row << format("%0.03f", order.business_third_party_delivery_charge_all)
        @row << format("%0.03f", order.business_food_club_charges_all)
        @row << format("%0.03f", order.fixed_fc_charge.to_f)

        if type == "online"
          @row << format("%0.03f", order.card_charge)
        end

        @row << format("%0.03f", order.third_party_payable_amount_business_all)

        if type == "cash"
          @row << format("%0.03f", order.business_transferrable_amount)
        end

        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.transporter.name

        if type == "cash"
          @row << (order.paid_by_admin ? "PAID on #{order.paid_by_admin_at&.strftime('%d/%m/%Y at %I:%M %p')}" : "Not Paid")
        end

        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      if type == "cash"
        csv << ["TOTAL", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_third_party_delivery_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_food_club_charges_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_payable_amount_business_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_transferrable_amount).sum)]
      else
        csv << ["TOTAL", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_third_party_delivery_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:business_food_club_charges_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:card_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_payable_amount_business_all).map(&:to_f).sum.to_f)]
      end

      csv << ["Total Orders", all.size]
      csv << ["Total Payable Amount", format("%0.03f", all.reload.map(&:third_party_payable_amount_business_all).map(&:to_f).sum) + " " + currency]
    end
  end

  def self.restaurant_delivery_transaction_report_csv(type, country_id)
    country_name = country_id.present? ? Country.find(country_id).name : "All"

    CSV.generate do |csv|
      header = "Restaurant Settle Amount Report (#{type.titleize})"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Country: " + country_name]

      if type == "cash"
        second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "FC Fixed Charge (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      else
        second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "FC Fixed Charge (#{currency})", "Card Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.restaurant&.title.presence || "NA"
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)

        if type == "online"
          @row << format("%0.03f", order.third_party_refund_charge_all)
        end

        @row << format("%0.03f", order.fixed_fc_charge.to_f)

        if type == "online"
          @row << format("%0.03f", order.card_charge)
          @row << format("%0.03f", order.restaurant_payable_amount_business_all)
        end

        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.transporter&.name
        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      if type == "cash"
        csv << ["TOTAL", "", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f)]

        csv << ["Total Orders", all.size]
        csv << ["Total Order Amount", format("%0.03f", all.reload.map(&:total_amount).map(&:to_f).sum) + " " + currency]
      else
        csv << ["TOTAL", "", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:card_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:restaurant_payable_amount_business_all).map(&:to_f).sum.to_f)]

        csv << ["Total Orders", all.size]
        csv << ["Total Payable Amount", format("%0.03f", all.reload.map(&:restaurant_payable_amount_business_all).map(&:to_f).sum) + " " + currency]
      end
    end
  end

  def self.business_transaction_report_csv(type)
    CSV.generate do |csv|
      header = "Restaurant Settle Amount Report (#{type.titleize})"
      currency = all.first&.currency_code_en.to_s
      csv << [header]

      if type == "cash"
        second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "FC Fixed Charge (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      else
        second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Refund Charge (#{currency})", "FC Fixed Charge (#{currency})", "Card Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver", "Comments"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)

        if type == "online"
          @row << format("%0.03f", order.third_party_refund_charge_all)
        end

        @row << format("%0.03f", order.fixed_fc_charge.to_f)

        if type == "online"
          @row << format("%0.03f", order.card_charge)
          @row << format("%0.03f", order.restaurant_payable_amount_business_all)
        end

        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.transporter&.name
        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      if type == "cash"
        csv << ["TOTAL", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f)]

        csv << ["Total Orders", all.size]
        csv << ["Total Order Amount", format("%0.03f", all.reload.map(&:total_amount).map(&:to_f).sum) + " " + currency]
      else
        csv << ["TOTAL", "", "", "", "", "", format("%0.03f", all.map(&:total_amount).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:third_party_refund_charge_all).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:fixed_fc_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:card_charge).map(&:to_f).sum.to_f), format("%0.03f", all.map(&:restaurant_payable_amount_business_all).map(&:to_f).sum.to_f)]

        csv << ["Total Orders", all.size]
        csv << ["Total Payable Amount", format("%0.03f", all.reload.map(&:restaurant_payable_amount_business_all).map(&:to_f).sum) + " " + currency]
      end
    end
  end

  def self.foodclub_delivery_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Food Club Delivery Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Payment Type", "Driver", "Order Stage", "Comments"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.landline.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.transporter&.name.presence || "NA"
        @row << order.current_status
        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.foodclub_delivery_cancelled_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Food Club Delivery Cancelled Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Payment Type", "Driver", "Cancelled at", "Cancelled by", "Cancel Reason", "Comments"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        currency = order.branch.currency_code_en
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.landline.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.transporter&.name.presence || "NA"
        @row << order.cancelled_at&.strftime("%B %d %Y %I:%M%p")
        @row << order.cancel_request_by
        @row << order.cancellation_reason.to_s.squish
        @row << (order.changed_delivery ? "Changed Order" : "")
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.settled_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Settled Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Payment Type"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.landline.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.rejected_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Rejected Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Payment Type", "Reject Reason"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.landline.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.cancel_reason.to_s.squish
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.cancelled_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Cancelled Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Payment Type", "Cancelled at", "Cancelled by", "Cancel Reason"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << order.contact.presence || "NA"
        @row << order.landline.presence || "NA"
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.cancelled_at&.strftime("%B %d %Y %I:%M%p")
        @row << order.cancel_request_by
        @row << order.cancellation_reason.to_s.squish
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.dine_in_orders_list_csv(branch_name, area_name, start_date, end_date)
    CSV.generate do |csv|
      header = "Dine In Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Area: " + area_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Order Id", "Branch", "Customer Name", "Customer Mobile", "Order Time", "Total Amount (#{currency})", "Payment Type", "Order Type", "Table No.", "Order Stage"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << (order.branch&.address.presence || "NA")
        @row << order.user.name
        @row << (order.contact.presence || "NA")
        @row << order.created_at.strftime("%B %d %Y %I:%M %p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "Online" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << (order.table_number.present? ? "DINE IN" : "TAKEAWAY")
        @row << order.table_number
        @row << order.current_status
        csv << @row
      end

      currency_code = all.first&.currency_code_en || "BHD"
      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
      csv << ["Total Credit Card Machine Orders", all.credit_card_machine_orders.size]
      csv << ["Total Credit Card Machine Orders Amount", format("%0.03f", all.credit_card_machine_orders.reload.pluck(:total_amount).sum) + " " + currency_code]
    end
  end

  def self.admin_orders_list_csv(start_date, end_date, comments)
    CSV.generate do |csv|
      header = "Orders List"
      currency = all.first&.branch&.currency_code_en.to_s
      csv << [header]
      csv << ["Start Date: " + start_date.to_date.strftime("%Y-%m-%d"), "End Date: " + end_date.to_date.strftime("%Y-%m-%d")]

      if comments
        second_row = ["ID", "Restaurant Name", "Branch", "Order Type", "On Demand", "Delivery Type", "Order Time", "Total Amount (#{currency})", "Customer Name", "Transporter", "Status", "Distance(km)", "Comments"]
      else
        second_row = ["ID", "Restaurant Name", "Branch", "Order Type", "On Demand", "Delivery Type", "Order Time", "Total Amount (#{currency})", "Customer Name", "Transporter", "Status", "Distance(km)"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch.restaurant.title
        @row << order.branch.address
        @row << (order.order_type == "prepaid" ? "Online" : order.order_type == "postpaid" ? "Cash on delivery" : "Credit Card Machine")
        @row << (order.on_demand ? "On Demand" : "")
        @row << delivery_type = order.third_party_delivery ? "Food Club" : "Restaurant"
        @row << order.created_at.strftime("%d %b %Y %l:%M%p")
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.user ? order.user.name : order.cart.user.name)
        @row << order.transporter&.name.to_s
        @row << order.current_status
        @row << order.distance

        if comments
          if order.dine_in
            @row << (order.table_number.present? ? "DINE IN" : "TAKEAWAY")
          else
            @row << (order.changed_delivery ? "Changed Order" : "")
          end
        end

        csv << @row
      end
    end
  end

  def driver_performance_csv(admin)
    CSV.generate do |csv|
      header = "Driver Performance for Order Id: " + id.to_s
      csv << [header]
      csv << ["Driver: " + transporter&.name.to_s]

      if admin
        if transporter&.delivery_company
          csv << ["Delivery Company: ", transporter.delivery_company.name]
        else
          csv << ["Driver Restaurant: ", transporter.branch_transports.first.branch.restaurant.title]
        end
      end

      csv << ["Action", "Time", "Duration"]
      csv << ["Driver Assigned At:", driver_assigned_at&.strftime("%d %b %Y %l:%M:%S %p"), ""]
      csv << ["Driver Accepted Order At:", driver_accepted_at&.strftime("%d %b %Y %l:%M:%S %p"), ((driver_accepted_at && driver_assigned_at) ? ApplicationController.helpers.time_diff(driver_accepted_at, driver_assigned_at) : "")]
      csv << ["Driver Onway At:", pickedup_at&.strftime("%d %b %Y %l:%M:%S %p"), ((pickedup_at && driver_accepted_at) ? ApplicationController.helpers.time_diff(pickedup_at, driver_accepted_at) : "")]
      csv << ["Order Delivered At:", delivered_at&.strftime("%d %b %Y %l:%M:%S %p"), ((delivered_at && pickedup_at) ? ApplicationController.helpers.time_diff(delivered_at, pickedup_at) : "")]
    end
  end

  def self.transporter_order_list_csv(transporter, start_date, end_date)
    CSV.generate do |csv|
      header = "Order List for " + transporter.name + " from " + start_date.to_date.strftime("%Y-%m-%d") + " to " + end_date.to_date.strftime("%Y-%m-%d")
      csv << [header]

      second_row = ["ID", "Restaurant Name", "Branch", "Order Time", "Driver Assigned At", "Driver Accepted Order At", "Accept Time", "Driver Onway At", "Onway Time", "Order Delivered At", "Delivery Time", "Status"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        currency = order.branch.currency_code_en
        @row = []
        @row << order.id
        @row << order.branch.restaurant.title
        @row << order.branch.address
        @row << order.created_at.strftime("%d %b %Y %l:%M:%S %p")
        @row << order.driver_assigned_at&.strftime("%d %b %Y %l:%M:%S %p")
        @row << order.driver_accepted_at&.strftime("%d %b %Y %l:%M:%S %p")

        if order.driver_accepted_at && order.driver_assigned_at
          @row << ApplicationController.helpers.time_diff(order.driver_accepted_at, order.driver_assigned_at)
        else
          @row << ""
        end

        @row << order.pickedup_at&.strftime("%d %b %Y %l:%M:%S %p")

        if order.pickedup_at && order.driver_accepted_at
          @row << ApplicationController.helpers.time_diff(order.pickedup_at, order.driver_accepted_at)
        else
          @row << ""
        end

        @row << order.delivered_at&.strftime("%d %b %Y %l:%M:%S %p")

        if order.delivered_at && order.pickedup_at
          @row << ApplicationController.helpers.time_diff(order.delivered_at, order.pickedup_at)
        else
          @row << ""
        end

        @row << order.current_status
        csv << @row
      end
    end
  end

  def self.active_order_list_csv(state)
    CSV.generate do |csv|
      header = "#{state.camelize} Orders List"
      currency = all.first&.currency_code_en.to_s
      csv << [header]

      if state == "active"
        second_row = ["Driver", "CPR No", "Order Id", "Restaurant", "Branch", "Customer Name", "Order Time", "Total Amount (#{currency})", "Payment By", "Order Stage", "Distance(km)"]
      else
        second_row = ["Driver", "Order Id", "Restaurant", "Branch", "Customer Name", "Order Time", "Total Amount (#{currency})", "Payment By", "Order Stage", "Distance(km)"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.transporter.name
        @row << order.transporter.cpr_number if (state == "active")
        @row << order.id
        @row << (order.branch&.restaurant&.title.presence || "Not Available")
        @row << (order.branch&.address.presence || "Not available")
        @row << order.user.name
        @row << order.created_at.strftime('%B %d %Y %I:%M %p')
        @row << format("%0.03f", order.total_amount.to_f)
        @row << (order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE")
        @row << order.current_status
        @row << order.distance
        csv << @row
      end

      csv << ["Total Orders", all.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.pluck(:total_amount).sum) + " " + currency]
      csv << ["Total Cash Orders", all.cash_orders.size]
      csv << ["Total Cash Orders Amount", format("%0.03f", all.cash_orders.reload.pluck(:total_amount).sum) + " " + currency]
      csv << ["Total Online Orders", all.online_orders.size]
      csv << ["Total Online Orders Amount", format("%0.03f", all.online_orders.reload.pluck(:total_amount).sum) + " " + currency]
    end
  end

  def self.refund_order_list_csv(country_id, start_date, end_date)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "Cancelled Orders List"
      currency = all.first&.branch&.currency_code_en.to_s
      csv << [header]

      csv << ["Country: " + country_name, "Start Date: " + start_date, "End Date: " + end_date]
      second_row = ["ID", "Restaurant Name", "Branch Address", "Order Type", "Total Amount (#{currency})", "Customer Name", "Cancelled At", "Cancel Requested By", "Cancel Reason", "Cancel Notes", "Refund Status", "Fault", "Refund Notes"]
      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id
        @row << order.branch.restaurant.title
        @row << order.branch.address
        @row << (order.order_type == "prepaid" ? "Online" : order.order_type == "postpaid" ? "Cash on delivery" : "Credit Card Machine")
        @row << order.total_amount
        @row << (order.user ? order.user.name : order.cart.user.name)
        @row << order.cancelled_at&.strftime("%B %d %Y %I:%M%p")
        @row << order.cancel_request_by
        @row << order.cancellation_reason
        @row << order.cancel_notes
        @row << (order.refund == true ? "REFUND" : (order.refund == false ? "NO REFUND" : "PENDING"))
        @row << order.refund_fault
        @row << order.refund_notes
        csv << @row
      end
    end
  end

  def self.points_redeemed_report_csv(country_id, start_date, end_date, user)
    country_name = country_id.present? ? Country.find(country_id).name : "All"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "Points Settlement Report"
      currency_code = all.first&.currency_code_en.to_s
      csv << [header]

      if user == "business"
        csv << ["Start Date: " + start_date, "End Date: " + end_date]
      else
        csv << ["Country: " + country_name, "Start Date: " + start_date, "End Date: " + end_date]
      end

      if user == "business"
        second_row = ["ID", "Branch Address", "Order Type", "Total Amount (#{currency_code})", "Customer Name", "Credit Points", "Debit Points"]
      else
        second_row = ["ID", "Restaurant Name", "Branch Address", "Order Type", "Total Amount (#{currency_code})", "Customer Name", "Credit Points", "Debit Points"]
      end

      csv << second_row

      all.order_by_date_desc.each do |order|
        @row = []
        @row << order.id

        if user == "admin"
          @row << order.branch.restaurant.title
        end

        @row << order.branch.address
        @row << (order.order_type == "prepaid" ? "Online" : order.order_type == "postpaid" ? "Cash on delivery" : "Credit Card Machine")
        @row << order.total_amount
        @row << (order.user ? order.user.name : order.cart.user.name)
        @row << format("%0.03f", order.points.select { |p| p.point_type == "Credit" }.map(&:user_point).sum.to_f)
        @row << format("%0.03f", order.points.select { |p| p.point_type == "Debit" }.map(&:user_point).sum.to_f)
        csv << @row
      end

      csv << ["Total Orders", all.reload.size]
      csv << ["Total Order Amount", format("%0.03f", all.reload.map(&:total_amount).map(&:to_f).sum) + " " + currency_code]
      csv << ["Total Credit Points", format("%0.03f", all.reload.map(&:total_credit_points).map(&:to_f).sum)]
      csv << ["Total Debit Points", format("%0.03f", all.reload.map(&:total_debit_points).map(&:to_f).sum)]
    end
  end

  def self.settle_amount_list_csv(start_date, end_date, company)
    CSV.generate do |csv|
      header = "Settle Amount Orders List for " + company.name
      currency = all.first&.branch&.currency_code_en.to_s
      csv << [header]
      csv << ["Start Date: " + start_date.to_date.strftime("%Y-%m-%d"), "End Date: " + end_date.to_date.strftime("%Y-%m-%d")]

      second_row = ["Order Id", "Restaurant", "Branch", "Customer Name", "Customer Mobile", "Customer Phone", "Order Time", "Total Amount (#{currency})", "Service Charge (#{currency})", "Refund Charge (#{currency})", "Payable Amount (#{currency})", "Payment By", "Order Stage", "Driver"]
      csv << second_row

      all.order(:id).each do |order|
        @row = []
        @row << order.id
        @row << restaurant = order.branch&.restaurant&.title.presence || "NA"
        @row << branch = order.branch&.address.presence || "NA"
        @row << order.user.name
        @row << cust_mobile = order.contact.presence || "NA"
        @row << cust_phone = order.landline.presence || "NA"
        @row << order.created_at.strftime('%B %d %Y %I:%M %p')
        @row << format("%0.03f", order.third_party_total_amount.to_f)
        @row << format("%0.03f", order.delivery_charge.to_f)
        @row << format("%0.03f", order.third_party_refund_charge.to_f)
        @row << format("%0.03f", order.third_party_payable_amount.to_f)
        @row << payment_by = order.payment_mode == "online" ? "ONLINE" : order.payment_mode == "COD" ? "CASH" : "CREDIT CARD MACHINE"
        @row << order.current_status
        @row << order.transporter.name
        csv << @row
      end
    end
  end

  def incident_report_csv
    incident = order_incident
    reporter = User.find_by(id: incident.reported_by)

    CSV.generate do |csv|
      header = "Incident Report for Order Id #{id}"
      csv << [header]

      csv << [""]
      csv << ["ORDER DETAILS"]
      csv << ["Order Id: #{id}"]
      csv << ["Order Time:", created_at.strftime("%B %d %Y %I:%M%p")]
      csv << ["Cancelled At:", cancelled_at&.strftime("%B %d %Y %I:%M%p")]
      csv << ["Restaurant:", branch.restaurant.title]
      csv << ["Branch:", branch.address]
      csv << ["Items Ordered:", order_items.map { |i| "#{i.quantity} #{i.menu_item.item_name}" }.join(", ")]

      csv << [""]
      csv << ["PERSON WHO CANCELLED THE ORDER"]
      csv << ["Person Name:", reporter.name]
      csv << ["Person Number:", reporter.country_code.to_s + reporter.contact.to_s]
      csv << ["Person Email:", reporter.email]
      csv << ["Person Occupation:", reporter.auths.first&.role.to_s.titleize]

      csv << [""]
      csv << ["COMPLAINT & WITNESS DETAILS"]
      csv << ["Complaint On:", (incident.complaint_on.to_s + " (" + incident.item_type.to_s + ")")]
      csv << ["Complaint Description:", incident.complaint_description]
      csv << ["Refund Required:", (incident.refund_required ? "Yes" : "No")]
      csv << ["Witness Name:", incident.witness_name]
      csv << ["Witness Number:", incident.witness_number]
      csv << ["Witness Description:", incident.witness_description]
      csv << ["Call Center Executive:", (User.find_by(id: incident.created_by)&.name)]
    end
  end

  def self.calendar_report_csv(event_date)
    CSV.generate do |csv|
      header = event_date.event.title + " : " + (event_date.start_date.strftime("%d/%m/%Y").to_s + "#{event_date.end_date ? '-' : ''}" + event_date.end_date&.strftime("%d/%m/%Y").to_s)
      csv << [header]

      second_row = ["Restaurant", "Branch", "Delivery Orders", "Delivery Order Amount", "Dine In Orders", "Dine In Order Amount", "Total Orders", "Total Order Amount"]
      csv << second_row

      all.group_by(&:branch_id).each do |branch_id, orders|
        @row = []
        branch = Branch.find(branch_id)

        @row << branch.restaurant.title
        @row << branch.address
        @row << orders.select { |o| o.dine_in == false }.size
        @row << format("%0.03f", orders.select { |o| o.dine_in == false }.map(&:total_amount).map(&:to_f).sum)
        @row << orders.select { |o| o.dine_in == true }.size
        @row << format("%0.03f", orders.select { |o| o.dine_in == true }.map(&:total_amount).map(&:to_f).sum)
        @row << orders.size
        @row << format("%0.03f", orders.map(&:total_amount).map(&:to_f).sum)
        csv << @row
      end
    end
  end

  private

  def assign_country_to_user
    if self.user && self.user.country_id.nil?
      self.user.update(country_id: branch&.restaurant&.country_id)
    end
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
end
