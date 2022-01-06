class EventsController < ApplicationController
  before_action :require_admin_logged_in
  layout "admin_application"

  def index
    @events = Event.includes(:event_countries, :countries)
    @events = @events.where(countries: { id: @admin.country_id }) unless helpers.is_super_admin?(@admin)
    @countries = @events.joins(:countries).pluck("countries.name, countries.id").uniq.sort
    @events = @events.where(countries: { id: params[:searched_country_id] }) if params[:searched_country_id].present?
    @events = @events.where("events.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @events = @events.order(:title)

    respond_to do |format|
      format.html {}
      format.csv { send_data @events.event_list_csv(params[:searched_country_id]), filename: "event_list.csv" }
    end
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      if params[:country_ids].present?
        params[:country_ids].each do |country_id|
          @event.event_countries.create(country_id: country_id)
        end
      end

      flash[:success] = "Event Created Successfully!"
      redirect_to events_path
    else
      flash[:error] = @event.errors.full_messages.first.to_s
      render "new"
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id])

    if @event.update(event_params)
      if helpers.is_super_admin?(@admin)
        @event.event_countries.destroy_all

        if params[:country_ids].present?
          params[:country_ids].each do |country_id|
            @event.event_countries.create(country_id: country_id)
          end
        end
      end

      flash[:success] = "Event Uptated Successfully!"
      redirect_to events_path
    else
      flash[:error] = @event.errors.full_messages.first.to_s
      render "edit"
    end
  end

  def show
    @event = Event.find(params[:id])
  end

  def destroy
    @event = Event.find(params[:id])

    if @event.destroy
      flash[:success] = "Event Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to events_path
  end

  def event_date_list
    @event = Event.find(params[:id])
    @dates = @event.event_dates.order(:start_date)
  end

  def event_calendar
    @events = Event.includes(:event_countries, :countries)
    @events = @events.where(countries: { id: @admin.country_id }) unless helpers.is_super_admin?(@admin)
    @countries = @events.joins(:countries).pluck("countries.name, countries.id").uniq.sort
    @events = @events.where(countries: { id: params[:searched_country_id] }) if params[:searched_country_id].present?
    @events = @events.where("events.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @events = @events.order(:title)
    @event_dates = EventDate.where(event_id: @events.pluck(:id)).map { |e| { id: e.id, title: e.event.title, start: e.start_date.strftime("%Y-%m-%d"), end: e.end_date&.strftime("%Y-%m-%d").to_s } }.to_json
  end

  def add_event_date
    @event = Event.find_by(title: params[:event_title])
    @date = params[:event_date]&.to_date
    @event.event_dates.create(start_date: @date) if @date.present?
    flash.now[:success] = "Event Added Successfuly to this Date"
  end

  def edit_event_date
    @event_date = EventDate.find_by(id: params[:event_id])
    @start_date = params[:start_date]&.to_date
    @end_date = params[:end_date]&.to_date
    @event_date.update(start_date: (@start_date + 1.day)) if @start_date.present?
    @event_date.update(end_date: (@end_date + 1.day)) if @end_date.present?
    flash.now[:success] = "Event Updated Successfuly to this Date"
  end

  def remove_event_date
    @event_date = EventDate.find_by(id: params[:event_id])
    @event_date&.destroy
    flash.now[:success] = "Event Successfuly Removed from this Date"
  end

  private

  def event_params
    params.require(:event).permit(:title, :description)
  end
end
