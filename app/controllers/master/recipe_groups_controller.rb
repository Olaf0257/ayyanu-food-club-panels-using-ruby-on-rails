class Master::RecipeGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @recipe_groups = RecipeGroup.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @recipe_group = current_restaurant.recipe_groups.new
  end

  def create
    @recipe_group = current_restaurant.recipe_groups.new(recipe_group_params)
    if @recipe_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_recipe_groups_path
    else
      flash[:error] = @recipe_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @recipe_group = RecipeGroup.find_by(id: params[:id])
  end

  def update
    @recipe_group = RecipeGroup.find_by(id: params[:id])
    if @recipe_group.update(recipe_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_recipe_groups_path
    else
      flash[:error] = @recipe_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @recipe_group = RecipeGroup.find_by(id: params[:id])
    if @recipe_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @recipe_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_recipe_groups_path
  end

  private

  def recipe_group_params
    params.require(:recipe_group).permit(:name, :restaurant_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
