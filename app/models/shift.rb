class Shift < ApplicationRecord
  belongs_to :restaurant
  belongs_to :user
  has_many :shift_dates
  has_many :schedule_shifts
end
