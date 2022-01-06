class Master::ComboMealGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @combo_meal_groups = ComboMealGroup.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @combo_meal_group = current_restaurant.combo_meal_groups.new
  end

  def create
    @combo_meal_group = current_restaurant.combo_meal_groups.new(combo_meal_group_params)
    if @combo_meal_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_combo_meal_groups_path
    else
      flash[:error] = @combo_meal_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @combo_meal_group = ComboMealGroup.find_by(id: params[:id])
  end

  def update
    @combo_meal_group = ComboMealGroup.find_by(id: params[:id])
    if @combo_meal_group.update(combo_meal_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_combo_meal_groups_path
    else
      flash[:error] = @combo_meal_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @combo_meal_group = ComboMealGroup.find_by(id: params[:id])
    if @combo_meal_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @combo_meal_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_combo_meal_groups_path
  end

  private

  def combo_meal_group_params
    params.require(:combo_meal_group).permit(:name, :restaurant_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end
end
