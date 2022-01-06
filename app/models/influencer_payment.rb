class InfluencerPayment < ApplicationRecord
  belongs_to :user

  validates :transaction_id, :amount, presence: true
end