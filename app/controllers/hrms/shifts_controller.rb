class Hrms::ShiftsController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit]
  layout "partner_application"
  include Hrms::ShiftsHelper


  def index
    @shifts = Shift.all  
    # if params[:branch].present?
    #   @shifts = Shift.search(params[:keyword]).where(restaurant: @restaurant]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    # else
    #   @shifts = Shift.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20) if params[:keyword].present?
    # end
  end

  def new
    @shift = @restaurant.shifts.new
    # @branches = @restaurant.branches
  end

  def create
    @shift = @restaurant.shifts.new(shift_params)
    if @shift.save
      flash[:success] = "Created Successfully!"
      redirect_to hrms_restaurant_shifts_path(restaurant_id: params[:restaurant_id]) 
    else
      flash[:error] = @shift.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @shift = Shift.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @shift = Shift.find_by(id: params[:id])
    if @shift.update(shift_params)
      flash[:success] = "Updated Successfully!"
      redirect_to hrms_restaurant_shifts_path(restaurant_id: params[:restaurant_id]) 
    else
      flash[:error] = @shift.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @shift = Shift.find_by(id: params[:id])
    if @shift.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @shift.errors.full_messages.join(", ")
    end
      redirect_to hrms_restaurant_shifts_path(restaurant_id: params[:restaurant_id]) 
  end

  def event_date_list
    @event = Shift.find(params[:id])
    @dates = @event.shift_dates.order(:start_date)
  end

  def assign_shift
    @events = Shift.all
    # @events = @events.where(countries: { id: @admin.country_id }) unless helpers.is_super_admin?(@admin)
    # @countries = @events.joins(:countries).pluck("countries.name, countries.id").uniq.sort
    # @events = @events.where(countries: { id: params[:searched_country_id] }) if params[:searched_country_id].present?
    # @events = @events.where("events.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    # @events = @events.order(:title)
    @event_dates = ShiftDate.all.map { |e| { id: e.id, title: e.shift.name, start: e.start_date.strftime("%Y-%m-%d"), end: e.end_date&.strftime("%Y-%m-%d").to_s } }.to_json
  end

  def add_event_date
    @event = Shift.find_by(name: params[:event_title])
    @date = params[:event_date]&.to_date
    @event.shift_dates.create(start_date: @date) if @date.present?
    flash.now[:success] = "Shift Added Successfuly to this Date"
  end

  def edit_event_date
    @event_date = ShiftDate.find_by(id: params[:event_id])
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date
    @event_date.update(start_date: (@start_date + 1.day)) if @start_date.present?
    @event_date.update(end_date: (@end_date + 1.day)) if @end_date.present?
    flash.now[:success] = "Shift Updated Successfuly to this Date"
  end

  def remove_event_date
    @event_date = ShiftDate.find_by(id: params[:event_id])
    @event_date&.destroy
    flash.now[:success] = "Shift Successfuly Removed from this Date"
  end

  def schedule_shift
    sunday = []
    monday = []
    tuesday = []
    wednesday = []
    thursday = []
    friday = []
    saturday = []
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @stations = Station.where(restaurant_id: decode_token(params[:restaurant_id]))

    ShiftDate.all.order("start_date asc").each do |shift|
      end_date = shift.end_date.blank? ? shift.start_date : shift.end_date
      ((shift.start_date)..(end_date)).to_a.each do |day|
        sunday << shift if day.sunday?
        monday << shift if day.monday?
        tuesday << shift if day.tuesday?
        wednesday << shift if day.wednesday?
        thursday << shift if day.thursday?
        friday << shift if day.friday?
        saturday << shift if day.saturday?
      end
    end
    @shift_dates = { sunday: sunday.compact, monday: monday.compact, tuesday: tuesday.compact, wednesday: wednesday.compact, thursday: thursday.compact, friday: friday.compact, saturday: saturday.compact }
  end

  def assign_employee
    employee_ids = params[:employee_ids].split(",")
    schedule_shift = ScheduleShift.new(restaurant_id:  decode_token(params[:restaurant_id]), employee_ids: params[:employee_ids], shift_id: params[:shift_id], station_id: params[:station_id], day_name: params[:day])
    if schedule_shift.save
      flash[:success] = "Shift scheduled successfully."
    else
      flash[:error] = "Something went wrong."
    end
    redirect_to schedule_shift_hrms_shifts_path(restaurant_id: params[:restaurant_id])
  end

  def fetch_station_employees
    shift_date = ShiftDate.find_by_id(params[:shift_id])
    @employees = find_employee_list_modal(shift_date, params[:station_id], params[:day_id])
  end

  def delete_employee
    schedule_shift = ScheduleShift.find_by_id(params[:schedule_shift_id])
    schedule_shift.delete
  end

  private

  def shift_params
    params.require(:shift).permit(:start_time, :restaurant_id, :end_time, :day, :name).merge!(user_id: @user.id)
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
