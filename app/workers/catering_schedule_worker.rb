class CateringScheduleWorker
  include Sidekiq::Worker
  sidekiq_options retry: true

  def perform(catering_schedule_id)
    schedule = CateringSchedule.find_by(id: catering_schedule_id)
    pos_check = PosCheck.unscoped.find_by(id: schedule&.pos_check_id)
    if schedule.present? && pos_check.present?
      pos_check.update(is_scheduled_check: false)
      PosCheck.save_check(pos_check)
      schedule.update(executed_at: DateTime.now)
    end
  end
end
