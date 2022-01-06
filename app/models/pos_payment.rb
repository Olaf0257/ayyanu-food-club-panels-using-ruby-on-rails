class PosPayment < ApplicationRecord
  has_many_attached :attachments
  belongs_to :payment_method
  belongs_to :pos_check
  belongs_to :currency_type, optional: true
end
