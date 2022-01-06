class InfluencerContract < ApplicationRecord
  belongs_to :user

  validates :start_date, :end_date, presence: true
  validate :date_validation

  def self.overlapping_range(new_range, contract_id, user_id)
    @overlap = false

    where.not(id: contract_id).where(user_id: user_id).find_each do |c|
      range = c.start_date..c.end_date

      if new_range.overlaps?(range)
        @overlap = true
        break
      end
    end

    @overlap
  end

  private

  def date_validation
    errors.add(:base, "End Date should be greater than Start Date") if self[:start_date] >= self[:end_date]
  end
end
