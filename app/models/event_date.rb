class EventDate < ApplicationRecord
  belongs_to :event

  validates :start_date, presence: true

  def self.calendar_report_csv(start_date, end_date)
    event_data = ApplicationController.helpers.event_calendar_order_date(all)

    CSV.generate do |csv|
      start_date = start_date.presence || "NA"
      end_date = end_date.presence || "NA"
      header = "Calendar Reports"
      csv << [header]
      csv << ["Start Date: " + start_date, "End Date: " + end_date]

      second_row = ["Event", "Dates", "Delivery Orders", "Delivery Order Amount", "Dine In Orders", "Dine In Order Amount", "Total Orders", "Total Order Amount"]
      csv << second_row

      event_data.each do |data|
        @row = []
        event_date = EventDate.find(data[:event_date_id])

        @row << event_date.event.title
        @row << (event_date.start_date.strftime("%d/%m/%Y").to_s + "#{event_date.end_date ? '-' : ''}" + event_date.end_date&.strftime("%d/%m/%Y").to_s)
        @row << data[:total_delivery_orders]
        @row << ApplicationController.helpers.number_with_precision(data[:total_delivery_order_amount], precison: 3)
        @row << data[:total_dine_in_orders]
        @row << ApplicationController.helpers.number_with_precision(data[:total_dine_in_order_amount], precison: 3)
        @row << data[:total_orders]
        @row << ApplicationController.helpers.number_with_precision(data[:total_order_amount], precison: 3)
        csv << @row
      end
    end
  end
end