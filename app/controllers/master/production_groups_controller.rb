class Master::ProductionGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @types = ["Menu Oriented", "Ingredients Oriented"]
    if params[:operation_type].present?
      @production_groups = ProductionGroup.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @production_groups = ProductionGroup.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @production_group = current_restaurant.production_groups.new
  end

  def create
    @production_group = current_restaurant.production_groups.new(production_group_params)
    if @production_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_production_groups_path
    else
      flash[:error] = @production_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @production_group = ProductionGroup.find_by(id: params[:id])
  end

  def update
    @production_group = ProductionGroup.find_by(id: params[:id])
    if @production_group.update(production_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_production_groups_path
    else
      flash[:error] = @production_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @production_group = ProductionGroup.find_by(id: params[:id])
    if @production_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @production_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_production_groups_path
  end

  private

  def production_group_params
    params.require(:production_group).permit(:name, :operation_type, :restaurant_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
