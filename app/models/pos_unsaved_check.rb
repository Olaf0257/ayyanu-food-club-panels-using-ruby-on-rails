class PosUnsavedCheck < ApplicationRecord
  belongs_to :pos_table, optional: true
  belongs_to :branch, optional: true
  belongs_to :pos_check, class_name: 'PosCheck', foreign_key: :pos_check_id, optional: true
  belongs_to :parant_pos_check, class_name: 'PosUnsavedCheck', foreign_key: :parent_unsaved_check_id, optional: true
  belongs_to :order_type, optional: true
  has_many :merged_checks, class_name: 'PosUnsavedCheck', foreign_key: :parent_unsaved_check_id
  belongs_to :driver, class_name: 'User', foreign_key: :driver_id, optional: true

  enum check_status: [:pending, :saved, :closed, :reopened]
end
