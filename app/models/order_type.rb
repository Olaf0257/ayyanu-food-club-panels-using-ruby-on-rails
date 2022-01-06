class OrderType < ApplicationRecord
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id
  belongs_to :last_updated_by, class_name: 'User', foreign_key: :last_updated_by_id, optional: true
  has_many :pos_checks
  has_many :pos_unsaved_checks
end
