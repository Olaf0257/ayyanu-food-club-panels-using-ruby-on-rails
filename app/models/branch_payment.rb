class BranchPayment < ApplicationRecord
  belongs_to :branch

  validates :transaction_id, :amount, presence: true

  def self.payment_list_csv(branch_id, start_date, end_date)
    branch_name = branch_id.present? ? Branch.find(branch_id).address : "All Branches"
    start_date = start_date.presence || "NA"
    end_date = end_date.presence || "NA"

    CSV.generate do |csv|
      header = "Branch Amount Transfers List"
      csv << [header]
      csv << ["Branch: " + branch_name, "Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Country", "Restaurant", "Branch", "Amount", "Transaction Id", "Transferred At"]
      csv << second_row

      all.each do |payment|
        @row = []
        @row << payment.branch.restaurant.country.name
        @row << payment.branch.restaurant.title
        @row << payment.branch.address
        @row << ApplicationController.helpers.number_with_precision(payment.amount, precision: 3) + " " + payment.branch.currency_code_en
        @row << payment.transaction_id
        @row << payment.created_at.strftime("%B %d %Y %I:%M %p")
        csv << @row
      end

      csv << ["Total Amount Transferred: ", ApplicationController.helpers.number_with_precision(all.pluck(:amount).sum.to_f, precision: 3).to_s + " " + all.first&.branch&.currency_code_en.to_s]
    end
  end
end