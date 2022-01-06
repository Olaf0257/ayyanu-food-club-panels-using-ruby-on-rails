class OrderTax < ApplicationRecord
  belongs_to :order

  validates :percentage, :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true
end
