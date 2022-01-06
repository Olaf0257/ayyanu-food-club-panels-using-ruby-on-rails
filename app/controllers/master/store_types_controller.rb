class Master::StoreTypesController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @store_types = StoreType.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @store_type = current_restaurant.store_types.new
  end

  def create
    @store_type = current_restaurant.store_types.new(store_type_params)
    if @store_type.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_store_types_path
    else
      flash[:error] = @store_type.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @store_type = StoreType.find_by(id: params[:id])
  end

  def update
    @store_type = StoreType.find_by(id: params[:id])
    if @store_type.update(store_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_store_types_path
    else
      flash[:error] = @store_type.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @store_type = StoreType.find_by(id: params[:id])
    if @store_type.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @store_type.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_store_types_path
  end

  private

  def store_type_params
    params.require(:store_type).permit(:name, :restaurant_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
