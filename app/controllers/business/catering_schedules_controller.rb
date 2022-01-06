class Business::CateringSchedulesController < ApplicationController
  layout "partner_application"
  def index
    @branch = Branch.find_by(id: decode_token(params[:branch_id]))
    @user = User.find_by(id: decode_token(params[:user_id]))
    if @branch.present?
      @schedules = @branch.catering_schedules.order('start_time asc')
    else
      flash[:error] = 'Branch not found'
      redirect_to :back
    end
  end

  def create
    @pos_check = PosCheck.find_by(id: params[:pos_check_id])
    @user = User.find_by(id: params[:user_id])
    if @pos_check.present?
      timezone = (params[:timezone].present? ?
        params[:timezone] :
        TZInfo::Timezone.all.find_all{ |z| z.name =~ /#{Regexp.quote(@user&.country&.name)}/ }.first) || 'UTC'
      current_time = DateTime.now.in_time_zone(timezone)
      start_time = params[:start_time].to_datetime.in_time_zone(timezone)
      unless start_time.between?(current_time, (current_time + 24.hours))
        @pos_check.update(is_scheduled_check: true)
        schedule = @pos_check.build_catering_schedule(
          start_time: start_time,
          end_time: params[:end_time].to_datetime.in_time_zone(timezone),
          branch_id: @pos_check.branch_id
        )
        if schedule.save
          job = CateringScheduleWorker.perform_at(start_time, schedule&.id)
          schedule.update(job_id: job)
        end
      else
        PosCheck.save_check(@pos_check)
      end
      flash[:success] = "Catering schedule created successfully"
      redirect_to business_partner_pos_dashboard_path(encode_token(@pos_check.branch.restaurant_id))
    else
      flash[:error] = 'Check not found'
      redirect_to :back
    end
  end

  def show
    @schedule = CateringSchedule.find_by(id: params[:id])
    @pos_check = PosCheck.unscoped.find_by(id: @schedule.pos_check_id)
  end

  def edit
    @schedule = CateringSchedule.find_by(id: params[:id])
  end

  def update
    @schedule = CateringSchedule.find_by(id: params[:id])
    @pos_check = PosCheck.unscoped.find_by(id: @schedule.pos_check_id)
    if @schedule.present? && @pos_check.present?
      timezone = (params[:timezone].present? ?
          params[:timezone] :
          TZInfo::Timezone.all.find_all{ |z| z.name =~ /#{Regexp.quote(@user&.country&.name)}/ }.first) || 'UTC'
      current_time = DateTime.now.in_time_zone(timezone)
      start_time = params[:start_time].to_datetime.in_time_zone(timezone)
      job = Sidekiq::ScheduledSet.new.find_job(@schedule.job_id)
      job.delete if job.present?
      unless start_time.between?(current_time, (current_time + 24.hours))
        @pos_check.update(is_scheduled_check: false)
        @schedule.assign_attributes(
          start_time: start_time,
          end_time: params[:end_time].to_datetime.in_time_zone(timezone),
          branch_id: @pos_check.branch_id
        )
        if @schedule.save
          @pos_check.update(is_scheduled_check: true)
          job = CateringScheduleWorker.perform_at(start_time, @schedule&.id)
          @schedule.update(job_id: job)
        end
      end
      render js: 'window.location.reload()'
    else
      render js: 'window.location.reload()'
    end
  end
end
