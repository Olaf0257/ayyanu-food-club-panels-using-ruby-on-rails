class PosUnsavedTransaction < ApplicationRecord
  belongs_to :branch
  belongs_to :pos_table, optional: true
  belongs_to :itemable, polymorphic: true
  belongs_to :pos_check, optional: true
  belongs_to :pos_transaction
  belongs_to :parent_pos_unsaved_transaction, class_name: 'PosUnsavedTransaction', foreign_key: :parent_pos_unsaved_transaction_id, optional: true
  has_many :addon_unsaved_pos_transactions, class_name: 'PosUnsavedTransaction', foreign_key: :parent_pos_unsaved_transaction_id
  enum transaction_status: [:pending, :saved, :shared_pending]
end
