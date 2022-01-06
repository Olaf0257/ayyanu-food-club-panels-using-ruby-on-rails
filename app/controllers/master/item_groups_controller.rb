class Master::ItemGroupsController < BrandsController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @types = ["Profit Contribution", "Expenses"]
    if params[:operation_type].present?
      @item_groups = ItemGroup.search(params[:keyword]).where(restaurant: current_restaurant, operation_type: params[:operation_type]).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    else
      @item_groups = ItemGroup.search(params[:keyword]).where(restaurant: current_restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
    end
  end

  def new
    @item_group = current_restaurant.item_groups.new
    @major_groups = current_restaurant.major_groups
  end

  def create
    @item_group = current_restaurant.item_groups.new(item_group_params)
    if @item_group.save
      flash[:success] = "Created Successfully!"
      redirect_to master_restaurant_item_groups_path
    else
      flash[:error] = @item_group.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @item_group = ItemGroup.find_by(id: params[:id])
    @major_groups = current_restaurant.major_groups
  end

  def update
    @item_group = ItemGroup.find_by(id: params[:id])
    if @item_group.update(item_group_params)
      flash[:success] = "Updated Successfully!"
      redirect_to master_restaurant_item_groups_path
    else
      flash[:error] = @item_group.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @item_group = ItemGroup.find_by(id: params[:id])
    if @item_group.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @item_group.errors.full_messages.join(", ")
    end
    redirect_to master_restaurant_item_groups_path
  end

  def filter_groups_by_type
    @major_groups = current_restaurant.major_groups.where(operation_type: params[:operation_type], country_ids: params[:country_ids])
  end

  private

  def item_group_params
    params.require(:item_group).permit(:name, :operation_type, :restaurant_id, :major_group_id, country_ids: [], branch_ids: []).merge!(user_id: @user.id)
  end

end
