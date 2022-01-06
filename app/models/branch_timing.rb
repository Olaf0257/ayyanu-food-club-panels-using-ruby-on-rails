class BranchTiming < ApplicationRecord
  DAY_NAMES = { 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday", 7 => "Sunday" }.freeze
  DAY_LIST = [["Monday", 1], ["Tuesday", 2], ["Wednesday", 3], ["Thursday", 4], ["Friday", 5], ["Saturday", 6], ["Sunday", 7]].freeze
  TIME_LIST = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "23:59"].freeze

  belongs_to :branch

  validates :opening_time, :closing_time, :day, presence: true
  validate :time_validation

  private

  def time_validation
    if self[:closing_time].to_s != "00:00" && (self[:opening_time] > self[:closing_time])
      errors.add(:base, "Closing Time should be greater than Opening Time")
    end
  end
end
