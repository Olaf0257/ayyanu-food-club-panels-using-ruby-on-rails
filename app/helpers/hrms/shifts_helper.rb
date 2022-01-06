module Hrms::ShiftsHelper
  def find_employee_list(shift_date, station, day)
    users = []
    shift_date&.shift.schedule_shifts&.where(day_name: day, station_id: station).each do |schedule_shift|
      users << User.where(id: schedule_shift.employee_ids.split)
    end 
    users.flatten.uniq
  end

  def find_employee_list_modal(shift_date, station, day)
    users = {}
    shift_date&.shift.schedule_shifts&.where(day_name: day, station_id: station).each do |schedule_shift|
      users[schedule_shift.id] = User.where(id: schedule_shift.employee_ids.split(",")).uniq
    end 
    users
  end
end
