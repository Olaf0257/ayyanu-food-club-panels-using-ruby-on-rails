class OrderDriver < ApplicationRecord
  belongs_to :order
  belongs_to :transporter, class_name: "User", foreign_key: "transporter_id"

  def self.order_driver_history_csv(order_id)
    CSV.generate do |csv|
      header = "Order Id #{order_id} Driver History"
      csv << [header]

      second_row = ["Driver", "CPR", "Assigned at", "Accepted at"]
      csv << second_row

      all.each do |driver|
        @row = []
        @row << driver.transporter.name
        @row << driver.transporter.cpr_number
        @row << driver.driver_assigned_at.strftime("%d/%m/%Y %l:%M:%S %p")
        @row << driver.driver_accepted_at&.strftime("%d/%m/%Y %l:%M:%S %p")
        csv << @row
      end
    end
  end
end
