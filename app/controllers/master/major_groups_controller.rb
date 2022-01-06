class Master::MajorGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @types = ["Profit Contribution", "Expenses"]
    if params[:operation_type].present?
      @major_groups = MajorGroup.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @major_groups = MajorGroup.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @major_group = current_restaurant.major_groups.new
    @over_groups = current_restaurant.over_groups
  end

  def create
    @major_group = current_restaurant.major_groups.new(major_group_params)
    if @major_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_major_groups_path
    else
      flash[:error] = @major_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @major_group = MajorGroup.find_by(id: params[:id])
    @over_groups = current_restaurant.over_groups
  end

  def update
    @major_group = MajorGroup.find_by(id: params[:id])
    if @major_group.update(major_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_major_groups_path
    else
      flash[:error] = @major_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @major_group = MajorGroup.find_by(id: params[:id])
    if @major_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @major_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_major_groups_path
  end

  def filter_over_groups_by_type
    @over_groups = current_restaurant.over_groups.where(operation_type: params[:operation_type], country_ids: params[:country_ids])
  end

  private

  def major_group_params
    params.require(:major_group).permit(:name, :operation_type, :restaurant_id, :over_group_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
