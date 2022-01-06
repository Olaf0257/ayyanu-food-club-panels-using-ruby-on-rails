class DistanceDeliveryCharge < ApplicationRecord
  validates :min_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :charge, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_order_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :country, optional: true

  def self.overlapping_range(new_range, charge_id, country)
    @overlap = false

    where.not(id: charge_id).where(country_id: country).find_each do |c|
      range = c.min_distance...c.max_distance

      if new_range.overlaps?(range)
        @overlap = true
        break
      end
    end

    @overlap
  end

  def self.delivery_charges_list_csv(delivery_charge)
    currency = all.first&.country&.currency_code
    country = all.first&.country&.name

    CSV.generate do |csv|
      header = "Distance wise Delivery Charges List for #{country}"
      csv << [header]

      second_row = ["Distance (km)", "Charge (#{currency})", "Min Order Amount (#{currency})", "Delivery Service (#{currency})", "Country"]
      csv << second_row

      all.each do |charge|
        @row = []
        @row << (charge.min_distance.to_s + " - " + charge.max_distance.to_s)
        @row << ApplicationController.helpers.number_with_precision(charge.charge, precision: 3)
        @row << ApplicationController.helpers.number_with_precision(charge.min_order_amount, precision: 3)
        @row << ApplicationController.helpers.number_with_precision(charge.delivery_service, precision: 3)
        @row << charge.country.name
        csv << @row
      end

      csv << []

      csv << ["Fixed Delivery Charge: " + delivery_charge.delivery_percentage.to_s + " %"]
    end
  end
end
