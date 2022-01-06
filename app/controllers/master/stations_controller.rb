class Master::StationsController < BrandsController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit]
  layout "partner_application"

  def index
    @branches = @restaurant.branches
    if params[:branch].present?
      @stations = Station.search(params[:keyword]).where(restaurant: @restaurant, branch_id: params[:branch]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @stations = Station.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def printers
    @types = ['All', 'Recipe', 'MenuItem']
    unless params[:operation_type].present?
      params[:operation_type] = 'All'
    end
    if params[:operation_type].eql?('Recipe') || params[:operation_type].eql?('All')
      @recipes = Recipe.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
    if params[:operation_type].eql?('MenuItem') || params[:operation_type].eql?('All')
      @menu_items = MenuItem.available.search_by_name(params[:keyword]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def add_printers
    @record = params[:type].constantize.find_by(id: params[:id])
    @record.update(station_ids: params[:menu_item][:station_ids].uniq.reject(&:blank?))
    redirect_back(fallback_location: add_printers_master_restaurant_stations_path)
  end

  def new
    @station = @restaurant.stations.new
    @branches = @restaurant.branches
  end

  def create
    @station = @restaurant.stations.new(station_params)
    if @station.save
      params.select { |k, _v| k.include?("opening_time") }.each do |k, v|
      day = k.split("_")[2]
      count = k.split("_")[3]
      if params["open_#{day}"] == "1"
        @station.timings.create(opening_time: params["opening_time_#{day}_#{count}"], closing_time: params["closing_time_#{day}_#{count}"], day: day)
        end
      end
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_stations_path
    else
      flash[:error] = @station.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @station = Station.find_by(id: params[:id])
    @branches = @restaurant.branches
    render layout: "partner_application"
  end

  def update
    @station = Station.find_by(id: params[:id])
    if @station.update(station_params)
      @station.timings.destroy_all
      params.select { |k, _v| k.include?("opening_time") }.each do |k, v|
      day = k.split("_")[2]
      count = k.split("_")[3]
      if params["open_#{day}"] == "1"
        @station.timings.create(opening_time: params["opening_time_#{day}_#{count}"], closing_time: params["closing_time_#{day}_#{count}"], day: day)
        end
      end
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_stations_path
    else
      flash[:error] = @station.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @station = Station.find_by(id: params[:id])
    if @station.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @station.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_stations_path
  end

  private

  def station_params
    params.require(:station).permit(:name, :printer_ip, :restaurant_id, :branch_id).merge!(user_id: @user.id)
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
