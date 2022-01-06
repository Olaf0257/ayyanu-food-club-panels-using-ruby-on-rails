class PosTable < ApplicationRecord
  belongs_to :branch
  has_many :pos_transactions
  has_many :pos_checks, dependent: :destroy
  enum table_status: [:not_selected, :running, :cancelled, :completed]
end
