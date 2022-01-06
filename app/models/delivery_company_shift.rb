class DeliveryCompanyShift < ApplicationRecord
  DAY_NAMES = { 0 => "Daily", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday", 7 => "Sunday" }.freeze
  DAY_LIST = [["Daily", 0], ["Monday", 1], ["Tuesday", 2], ["Wednesday", 3], ["Thursday", 4], ["Friday", 5], ["Saturday", 6], ["Sunday", 7]].freeze
  TIME_LIST = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30", "23:59"].freeze

  belongs_to :delivery_company
  has_and_belongs_to_many :users

  validates :start_time, :end_time, :day, presence: true
  validate :time_validation

  def as_json(options = {})
    @user = options[:logdinUser]
    @language = options[:language]
    super(options.merge(only: [:id, :start_time, :end_time], methods: [:day_name]))
  end

  def day_name
    DAY_NAMES[day]
  end

  def shift_duration
    if end_time > start_time
      end_time.to_time - start_time.to_time
    else
      ("23:59:59".to_time - start_time.to_time) + 1
    end
  end

  def self.shift_list_csv(company_name)
    CSV.generate do |csv|
      header = "Shifts List for " + company_name.to_s
      csv << [header]

      second_row = ["Day", "Start Time", "End Time", "Driver Count", "Driver Names"]
      csv << second_row

      all.each do |shift|
        @row = []
        @row << DeliveryCompanyShift::DAY_NAMES[shift.day]
        @row << shift.start_time
        @row << shift.end_time
        @row << shift.users.size
        @row << shift.users.pluck(:name).sort.join(" | ")
        csv << @row
      end
    end
  end

  private

  def time_validation
    if self[:day] != 0 && (self[:start_time] >= self[:end_time])
      errors.add(:base, "End Time should be greater than Start Time")
    end
  end
end
