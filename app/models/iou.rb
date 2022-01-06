class Iou < ApplicationRecord
  belongs_to :order
  belongs_to :user
  belongs_to :transporter, class_name: "User", foreign_key: "transporter_id", optional: true

  scope :order_by_date_desc, -> { order("ious.created_at DESC") }

  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at, :user_id, :transporter_id], methods: [:order_date, :order_amount]))
  end

  def self.create_iou(user, order_id, transporter_id, amount)
    iou = new(user_id: user.id, order_id: order_id, transporter_id: transporter_id, paid_amount: amount)
    iou.save!
    !iou.id.nil? ? { code: 200, result: iou } : { code: 400, result: iou.errors.full_messages.join(", ") }
    iou
  end

  def order_date
    order.created_at
  end

  def order_amount
    order.total_amount
  end

  def self.find_transporter(user)
    where(transporter_id: user.id)
  end

  def self.update_iou_list(user)
    list = Iou.find_transporter(user)
    list&.update_all(is_received: true)
  end

  def self.manage_ious_list_csv(branch_name)
    CSV.generate do |csv|
      header = "MANAGE I.O.U List"
      currency = all.first&.order&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name]

      second_row = ["S.No", "Customer Name", "Transporter Name", "Cpr Number", "Order Id", "Iou Date", "Order Amount (#{currency})", "Iou Amount (#{currency})", "Total Amount (#{currency})", "Status"]
      csv << second_row

      all.includes(:transporter, order: { branch: { restaurant: :country } }).order_by_date_desc.each do |iou|
        @row = []
        @row << iou.id
        @row << iou.user.name
        @row << iou.transporter.name
        @row << iou.transporter.cpr_number
        @row << iou.order_id
        @row << iou.created_at.strftime("%B %d %Y %I:%M%p")
        @row << format("%0.03f", iou.order.total_amount.to_f)
        @row << format("%0.03f", iou.paid_amount.to_f)
        @row << format("%0.03f", iou.order.total_amount.to_f + iou.paid_amount.to_f)
        @row << (iou.is_received == true ? "Received" : "Pending")
        csv << @row
      end
    end
  end

  def self.delivery_company_ious_list_csv
    CSV.generate do |csv|
      header = "MANAGE I.O.U List"
      currency = all.first&.order&.currency_code_en.to_s
      csv << [header]

      second_row = ["S.No", "Driver", "CPR", "Customer", "Order Id", "Restaurant", "Branch", "Iou Date", "Amount (#{currency})", "Status"]
      csv << second_row

      all.includes(:transporter, order: { branch: { restaurant: :country } }).order_by_date_desc.each do |iou|
        currency = iou.order.branch.currency_code_en
        @row = []
        @row << iou.id
        @row << iou.transporter.name
        @row << iou.transporter.cpr_number
        @row << iou.order.user&.name
        @row << iou.order_id
        @row << iou.order.branch.restaurant.title
        @row << iou.order.branch.address
        @row << iou.created_at.strftime("%B %d %Y %I:%M%p")
        @row << format("%0.03f", iou.paid_amount.to_f)
        @row << (iou.is_received == true ? "Received" : "Pending")
        csv << @row
      end
    end
  end
end
