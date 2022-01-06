class Master::StoresController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @store_types = current_restaurant.store_types
    if params[:branch].present?
      @stores = Store.search(params[:keyword]).where(restaurant: current_restaurant, branch_id: params[:branch]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @stores = Store.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @store = current_restaurant.stores.new
    @store_types = current_restaurant.store_types
    @taxes = Tax.where(country: current_restaurant.country)
    @branches = current_restaurant.branches
    @areas = get_coverage_area_web("", 1, 300).where(country: current_restaurant.country)
  end

  def create
    store_params_with_phone = store_params
    store_params_with_phone[:phone] = params[:store_phone_number] if params[:store_phone_number].present?
    @store = current_restaurant.stores.new(store_params_with_phone)
    if @store.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_stores_path
    else
      flash[:error] = @store.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @store = Store.find_by(id: params[:id])
    @store_types = current_restaurant.store_types
    @taxes = Tax.where(country: current_restaurant.country)
    @areas = get_coverage_area_web("", 1, 300).where(country: current_restaurant.country)
  end

  def update
    store_params_with_phone = store_params
    store_params_with_phone[:phone] = params[:store_phone_number] if params[:store_phone_number].present?
    @store = Store.find_by(id: params[:id])
    if @store.update(store_params_with_phone)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_stores_path
    else
      flash[:error] = @store.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @store = Store.find_by(id: params[:id])
    if @store.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @store.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_stores_path
  end

  private

  def store_params
    params.require(:store).permit(:name, :phone, :tax_id, :store_type_id, :address, :block, :road_no, :building, :floor, :additional_direction, :city_id, :area_id, store_category: [], branch_ids: [], country_ids: []).merge!(user_id: @user.id)
  end

end
