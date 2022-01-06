class AreasController < ApplicationController
  before_action :require_admin_logged_in

  def all_coverage_areas
    if @admin.class.name == "SuperAdmin"
      @coverage_areas = CoverageArea.includes(:city, :country).non_requested_areas
    else
      @coverage_areas = CoverageArea.where(countries: { id: @admin.country_id }).includes(:city, :country).non_requested_areas
    end

    @countries = Country.where(id: @coverage_areas.pluck(:country_id).uniq).pluck(:name, :id)
    @searchable_zones = Zone.where(id: @coverage_areas.pluck(:zone_id).uniq).pluck(:name, :id)
    @coverage_areas = @coverage_areas.where("area LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @coverage_areas = @coverage_areas.joins(:city).where("city LIKE ?", "%#{params[:searched_city]}%").distinct if params[:searched_city].present?
    @coverage_areas = @coverage_areas.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @coverage_areas = @coverage_areas.filter_by_zone(params[:searched_zone_id]) if params[:searched_zone_id].present?
    @coverage_areas = @coverage_areas.where(status: params[:status]) if params[:status].present?
    @coverage_areas = @coverage_areas.where.not(area: "No Area Present").order_by_name

    respond_to do |format|
      format.html do
        @coverage_areas = @coverage_areas.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv  { send_data @coverage_areas.area_list_csv(params[:searched_country_id], params[:searched_zone_id]), filename: "coverage_areas_list.csv" }
    end
  end

  def new_coverage_areas
    if @admin.class.name == "SuperAdmin"
      @coverage_areas = CoverageArea.includes(:city, :country).requested_areas
    else
      @coverage_areas = CoverageArea.where(countries: { id: @admin.country_id }).includes(:city, :country).requested_areas
    end

    @countries = Country.where(id: @coverage_areas.pluck(:country_id).uniq).pluck(:name, :id)
    @coverage_areas = @coverage_areas.where("area LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @coverage_areas = @coverage_areas.filter_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @coverage_areas = @coverage_areas.where.not(area: "No Area Present").order_by_name

    respond_to do |format|
      format.html do
        @coverage_areas = @coverage_areas.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv  { send_data @coverage_areas.new_area_list_csv(params[:searched_country_id]), filename: "new_coverage_areas_list.csv" }
    end
  end

  def download_coverage_area_format
    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv  { send_data CoverageArea.coverage_area_upload_format_csv, filename: "coverage_area_upload_format.csv" }
    end
  end

  def upload_coverage_areas
    import_data = CoverageArea.import(params[:file])
    flash[:success] = "Coverage Areas Imported Successfully!"
    redirect_to request.referer
  end

  def delete_coverage_area
    coverage_area = get_coverage_area_with_id(params[:coverage_area_id])

    if coverage_area.present?
      coverage_area.destroy
      send_json_response("Category remove", "success", {})
    end
  end

  def change_coverage_area
    @area = CoverageArea.find(params[:area_id])
    session[:return_to] = request.referer
    render layout: "admin_application"
  end

  def edit_coverage_area
    coverage_area = get_coverage_area_with_id(params[:coverage_area_id])

    if coverage_area.present?
      coverage_area.update(area: params[:coverage_area][:area], area_ar: params[:coverage_area][:area_ar], status: params[:coverage_area][:status].downcase, location: params[:address], latitude: params[:latitude], longitude: params[:longitude])
      city = City.find_or_create_by(city: params[:city])
      coverage_area.update(city_id: city&.id)

      if @admin.class.name == "SuperAdmin"
        coverage_area.update(country_id: params[:coverage_area][:country_id])
      else
        coverage_area.update(country_id: @admin.country_id)
      end

      flash[:success] = "Coverage Area Successfully Updated!"

      if params[:new_area].present?
        coverage_area.update(requested: false) if params[:coverage_area][:status].downcase == "active"
      end

      redirect_to session.delete(:return_to)
    end
  end

  def add_coverage_area
    country_id = @admin.class.name == "SuperAdmin" ? params[:coverage_area][:country_id] : @admin.country_id
    add_new_coverage_area(params[:coverage_area][:coverage_area], params[:coverage_area][:coverage_area_ar], params[:coverage_area][:city], country_id, params[:address], params[:latitude], params[:longitude])
    redirect_to all_coverage_areas_path
  end
end
