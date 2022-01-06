class PosTransaction < ApplicationRecord
  belongs_to :branch
  belongs_to :pos_table, optional: true
  belongs_to :itemable, polymorphic: true
  belongs_to :pos_check, optional: true
  belongs_to :parent_pos_transaction, class_name: 'PosTransaction', foreign_key: :parent_pos_transaction_id, optional: true
  belongs_to :parent_shared_transaction, class_name: 'PosTransaction', foreign_key: :shared_transaction_id, optional: true
  has_many :shared_transactions, class_name: 'PosTransaction', foreign_key: :shared_transaction_id
  has_many :addon_pos_transactions, class_name: 'PosTransaction', foreign_key: :parent_pos_transaction_id
  enum transaction_status: [:pending, :saved, :shared_pending]
  has_many :pos_unsaved_transactions, dependent: :destroy

  enum duration: ['Immediately', '5 Minutes', '10 Minutes', '15 Minutes']

  def get_color
    green_color = self.branch.restaurant.kds_colors.find_by(color: 'green')
    yellow_color = self.branch.restaurant.kds_colors.find_by(color: 'yellow')
    red_color = self.branch.restaurant.kds_colors.find_by(color: 'red')
    minute = ((Time.zone.now - self.created_at) / 1.minutes).to_i
    if((minute <= green_color.minutes) rescue nil)
      ['green', 'white']
    elsif((minute >= green_color.minutes && minute <= (green_color.minutes+yellow_color.minutes)) rescue nil)
      ['yellow', 'black']
    else
      ['red', 'white']
    end
  end
end
