class ZonesController < ApplicationController
  before_action :require_admin_logged_in

  def index
    @zones = Zone.joins(district: { state: :country }).distinct
    @zones = @zones.where(countries: { id: @admin.country_id }) if @admin.class.name != "SuperAdmin"
    @districts = @zones.pluck("districts.name, districts.id").sort
    @zones = @zones.search_by_name(params[:keyword]) if params[:keyword].present?
    @zones = @zones.search_by_district(params[:searched_district_id]) if params[:searched_district_id].present?
    @zones = @zones.order_by_date_desc

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv  { send_data @zones.zone_list_csv(params[:searched_district_id]), filename: "zones_list.csv" }
    end
  end

  def new
    @zone = Zone.new

    if @admin.class.name == "SuperAdmin"
      @districts = District.pluck(:name, :id)
    else
      @districts = District.includes(:state).where(states: { country_id: @admin.country_id }).pluck(:name, :id)
    end

    render layout: "admin_application"
  end

  def create
    @zone = Zone.new(zone_params)

    if @zone.save
      flash[:success] = "Zone Successfully Created!"
      redirect_to zones_path
    else
      flash[:error] = @zone.errors.full_messages.first.to_s
      redirect_to new_zone_path
    end
  end

  def edit
    @zone = Zone.find(params[:id])

    if @admin.class.name == "SuperAdmin"
      @districts = District.pluck(:name, :id)
    else
      @districts = District.includes(:state).where(states: { country_id: @admin.country_id }).pluck(:name, :id)
    end

    render layout: "admin_application"
  end

  def update
    @zone = Zone.find(params[:id])

    if @zone.update(zone_params)
      flash[:success] = "Zone Uptated Successfully!"
      redirect_to zones_path
    else
      flash[:error] = @zone.errors.full_messages.first.to_s
      redirect_to edit_zone_path(@zone)
    end
  end

  def show
    @zone = Zone.find(params[:id])
    @areas = @zone.coverage_areas.active_areas.order(:area)
    render layout: "admin_application"
  end

  def free_area_list
    @zone = Zone.find(params[:id])
    @areas = CoverageArea.active_areas.where(country_id: @zone.district.state.country_id, zone_id: nil).order(:area)
    @areas = @areas.where("area like ? ", "%#{params[:keyword]}%").order(:area) if params[:keyword].present?
  end

  def add_area_to_zone
    zone_id = params[:zone_id]

    if params[:area_ids].present?
      CoverageArea.where(id: params[:area_ids]).update_all(zone_id: zone_id)
      flash[:success] = "Areas Successfully Added to Zone!"
    else
      flash[:error] = "Please Select Area to Add"
    end

    redirect_to request.referer
  end

  def remove_area_from_zone
    area_id = params[:area_id]
    CoverageArea.find_by(id: area_id)&.update(zone_id: nil)
    render json: { code: 200 }
  end

  def destroy
    @zone = Zone.find(params[:id])

    if @zone&.destroy
      flash[:success] = "Zone Deleted Successfully!"
    else
      flash[:error] = "Cannot be Deleted"
    end

    redirect_to zones_path
  end

  private

  def zone_params
    params.require(:zone).permit(:name, :name_ar, :district_id)
  end
end
