class OrderRequest < ApplicationRecord
  belongs_to :user
  belongs_to :branch

  validates :base_price, :vat_price, :service_charge, :total_amount, presence: true

  def self.order_request_list_csv(branch_id, start_date, end_date)
    branch_name = branch_id.present? ? Branch.find(branch_id).address : "All Branches"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "On Demand Online List"
      currency = all.first&.branch&.currency_code_en.to_s
      csv << [header]
      csv << ["Branch: " + branch_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Branch", "Customer Name", "Customer Email", "Customer Contact", "Base Price (#{currency})", "Tax Price (#{currency})", "Service Charge (#{currency})", "Total Amount (#{currency})", "Requested At"]
      csv << second_row

      all.each do |request|
        @row = []
        @row << request.branch.address
        @row << request.user.name
        @row << request.user.email
        @row << request.mobile
        @row << ApplicationController.helpers.number_with_precision(request.base_price, precision: 3)
        @row << ApplicationController.helpers.number_with_precision(request.vat_price, precision: 3)
        @row << ApplicationController.helpers.number_with_precision(request.service_charge, precision: 3)
        @row << ApplicationController.helpers.number_with_precision(request.total_amount, precision: 3)
        @row << request.created_at.strftime("%B %d %Y %I:%M %p")
        csv << @row
      end
    end
  end
end