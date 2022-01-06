class TransporterTiming < ApplicationRecord
  belongs_to :user

  def session_duration
    if login_time && logout_time
      (logout_time - login_time).to_i
    else
      0
    end
  end

  def shift_duration
    total_time = 0

    user.delivery_company_shifts.each do |shift|
      if (DeliveryCompanyShift::DAY_NAMES[shift.day] == created_at.strftime("%A") || shift.day == 0)
        total_time += shift.shift_duration
      end
    end

    total_time
  end

  def shifts_done
    shifts = []

    user.delivery_company_shifts.each do |shift|
      if (DeliveryCompanyShift::DAY_NAMES[shift.day] == created_at.strftime("%A") || shift.day == 0) && login_time && ((login_time + 30.minutes).strftime("%H:%M") >= shift.start_time) && (login_time.strftime("%H:%M") <= shift.end_time)
        shifts << [created_at.to_date, shift.id]
      end
    end

    shifts
  end

  def punctual_shifts
    shifts = []

    user.delivery_company_shifts.each do |shift|
      if (DeliveryCompanyShift::DAY_NAMES[shift.day] == created_at.strftime("%A") || shift.day == 0) && login_time && ((login_time + 30.minutes).strftime("%H:%M") >= shift.start_time) && ((login_time + 5.minutes).strftime("%H:%M") <= shift.start_time)
        shifts << [created_at.to_date, shift.id]
      end
    end

    shifts
  end

  def late_shifts
    shifts_done - punctual_shifts
  end

  def busy_time
    busy_time = 0

    user.delivery_company_shifts.each do |shift|
      if (DeliveryCompanyShift::DAY_NAMES[shift.day] == created_at.strftime("%A") || shift.day == 0)
        busy_time += shift.shift_duration
      end
    end

    busy_time
  end

  def self.driver_timing_list_csv(user, start_date, end_date)
    CSV.generate do |csv|
      header = user.name + " Timings"
      csv << [header]

      if user.delivery_company
        csv << ["Company: " + user.delivery_company.name, "Start Date: " + start_date.strftime("%Y-%m-%d"), "End Date: " + end_date.strftime("%Y-%m-%d")]
      else
        csv << ["Restaurant: " + user.branches.first.restaurant.title, "Start Date: " + start_date.strftime("%Y-%m-%d"), "End Date: " + end_date.strftime("%Y-%m-%d")]
      end

      second_row = ["Day", "Login Time", "Logout Time", "Duration"]
      csv << second_row

      all.each do |timing|
        @row = []
        @row << timing.created_at&.strftime("%A")
        @row << timing.login_time&.strftime("%d %b %Y %l:%M:%S %p")
        @row << timing.logout_time&.strftime("%d %b %Y %l:%M:%S %p")
        @row << (ApplicationController.helpers.time_diff(timing.logout_time, timing.login_time) if timing.login_time && timing.logout_time)
        csv << @row
      end

      assigned_time = all.uniq { |t| t.created_at.to_date }.map(&:shift_duration).sum
      working_time = all.map(&:session_duration).sum

      csv << []

      if user.delivery_company_id
        csv << ["Total Assigned Time: " + ApplicationController.helpers.time_duration(assigned_time)]
      end

      csv << ["Total Working Time: " + ApplicationController.helpers.time_duration(working_time)]

      if user.delivery_company_id
        csv << ["Total Break Time: " + ApplicationController.helpers.time_duration(assigned_time - working_time)]
      end
    end
  end
end
