class Setup::UnitsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @units = Unit.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @unit = current_restaurant.units.new
  end

  def create
    @unit = current_restaurant.units.new(unit_params)
    if @unit.save
      flash[:success] = "Created Successfully!"
      redirect_to setup_restaurant_units_path
    else
      flash[:error] = @unit.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @unit = Unit.find_by(id: params[:id])
  end

  def update
    @unit = Unit.find_by(id: params[:id])
    if @unit.update(unit_params)
      flash[:success] = "Updated Successfully!"
      redirect_to setup_restaurant_units_path
    else
      flash[:error] = @unit.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @unit = Unit.find_by(id: params[:id])
    if @unit.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @unit.errors.full_messages.join(", ")
    end
    redirect_to setup_restaurant_units_path
  end

  private

  def unit_params
    params.require(:unit).permit(:name, :consists_of, :base_unit, :other_unit, :qty, :restaurant_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
