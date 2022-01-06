class Station < ApplicationRecord
  belongs_to :restaurant
  belongs_to :branch
  belongs_to :user
  has_many :timings, as: :timeable
  has_many :inventories, as: :inventoryable

  def self.search(condition)
    where("name like ?", "#{condition}%")
  end

  def opening_timing
    if timings.present?
      current_time = Time.current.to_time.strftime("%H:%M")
      todays_timings = timings.select { |t| Timing::DAY_NAMES[t.day] == Date.today.strftime("%A")  }
      time = todays_timings.select { |t| t.opening_time <=  current_time && t.closing_time >= current_time }.first&.opening_time
      time ||= todays_timings.select { |t| t.opening_time > current_time }.sort_by(&:opening_time).first&.opening_time
      time ||= todays_timings.select { |t| t.opening_time < current_time }.sort_by(&:opening_time).last&.opening_time
      time
    else
      self["opening_timing"]
    end
  end

  def closing_timing
    if timings.present?
      current_time = Time.current.to_time.strftime("%H:%M")
      todays_timings = timings.select { |t| Timing::DAY_NAMES[t.day] == Date.today.strftime("%A")  }
      time = todays_timings.select { |t| t.opening_time <=  current_time && t.closing_time >= current_time }.first&.closing_time
      time ||= todays_timings.select { |t| t.opening_time > current_time }.sort_by(&:opening_time).first&.closing_time
      time ||= todays_timings.select { |t| t.opening_time < current_time }.sort_by(&:opening_time).last&.closing_time
      time
    else
      self["closing_timing"]
    end
  end
end
