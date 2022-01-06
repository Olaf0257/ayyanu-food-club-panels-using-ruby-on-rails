class DistrictsController < ApplicationController
  before_action :require_admin_logged_in

  def index
    @districts = District.joins(state: :country).includes(state: :country).distinct

    if @admin.class.name == "SuperAdmin"
      @countries = @districts.pluck("countries.name, countries.id").sort
    else
      @districts = @districts.where(countries: { id: @admin.country_id })
    end

    @states = @districts.pluck("states.name, states.id").sort
    @districts = @districts.search_by_name(params[:keyword]) if params[:keyword].present?
    @districts = @districts.search_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @districts = @districts.search_by_state(params[:searched_state_id]) if params[:searched_state_id].present?
    @districts = @districts.order_by_date_desc

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv  { send_data @districts.district_list_csv(params[:searched_country_id], params[:searched_state_id]), filename: "districts_list.csv" }
    end
  end

  def state_list
    country = params[:country].presence
    country_code = CountryStateSelect.countries_collection.select { |i| i.first == country }.first.last
    @states = CS.states(country_code).values.sort
  end

  def new
    @district = District.new

    if @admin.class.name != "SuperAdmin"
      country_code = CountryStateSelect.countries_collection.select { |i| i.first == @admin.country.name }.first.last
      @states = CS.states(country_code).values.sort
    end

    render layout: "admin_application"
  end

  def create
    @district = District.new(district_params)
    country_id = @admin.class.name == "SuperAdmin" ? params[:country_id].presence : @admin.country_id
    state_id = State.find_or_create_by(name: params[:state], country_id: country_id)&.id
    @district.state_id = state_id

    if @district.save
      flash[:success] = "District Successfully Created!"
      redirect_to districts_path
    else
      flash[:error] = @district.errors.full_messages.first.to_s
      redirect_to new_district_path
    end
  end

  def edit
    @district = District.find(params[:id])
    country_code = CountryStateSelect.countries_collection.select { |i| i.first == @district.state.country.name }.first.last
    @states = CS.states(country_code).values.sort
    render layout: "admin_application"
  end

  def update
    @district = District.find(params[:id])
    country_id = @admin.class.name == "SuperAdmin" ? params[:country_id].presence : @admin.country_id
    state_id = State.find_or_create_by(name: params[:state], country_id: country_id)&.id
    @district.state_id = state_id

    if @district.update(district_params)
      flash[:success] = "District Uptated Successfully!"
      redirect_to districts_path
    else
      flash[:error] = @district.errors.full_messages.first.to_s
      redirect_to edit_district_path(@district)
    end
  end

  def show
    @district = District.find(params[:id])
    @zones = @district.zones.order(:name)
    render layout: "admin_application"
  end

  def destroy
    @district = District.find(params[:id])

    if @district.destroy
      flash[:success] = "District Deleted Successfully!"
    else
      flash[:error] = "Cannot be Deleted"
    end

    redirect_to districts_path
  end

  private

  def district_params
    params.require(:district).permit(:name)
  end
end
