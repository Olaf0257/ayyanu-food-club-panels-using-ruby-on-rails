class DeliveryCharge < ApplicationRecord
  validates :delivery_percentage, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
