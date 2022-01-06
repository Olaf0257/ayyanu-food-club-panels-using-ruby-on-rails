class Master::OverGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    #@branches = current_restaurant.branches
    #@countries = Country.where(name: @branches.pluck(:country))
    @types = ["Profit Contribution", "Expenses"]
    filter = {restaurant: current_restaurant.id}
    filter.merge!(operation_type: params[:operation_type]) if params[:operation_type].present?
    filter.merge!(country_ids: params[:country_id]) if params[:country_id].present?
    filter.merge!(branch_ids: params[:branch_id]) if params[:branch_id].present?
    @over_groups = OverGroup.search(params[:keyword]).where(filter).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @over_group = current_restaurant.over_groups.new
  end

  def create
    @over_group = current_restaurant.over_groups.new(over_group_params)
    if @over_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_over_groups_path
    else
      flash[:error] = @over_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @over_group = OverGroup.find_by(id: params[:id])
  end

  def update
    @over_group = OverGroup.find_by(id: params[:id])
    if @over_group.update(over_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_over_groups_path
    else
      flash[:error] = @over_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @over_group = OverGroup.find_by(id: params[:id])
    if @over_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @over_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_over_groups_path
  end

  private

  def over_group_params
    params.require(:over_group).permit(:name, :operation_type, :restaurant_id, :country_id, branch_ids: [], country_ids: []).merge!(user_id: @user.id)
  end

end
