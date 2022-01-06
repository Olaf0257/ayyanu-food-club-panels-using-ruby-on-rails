class CashType < ApplicationRecord
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id
  belongs_to :last_updated_by, class_name: 'User', foreign_key: :last_updated_by_id, optional: true
  belongs_to :restaurant

end
