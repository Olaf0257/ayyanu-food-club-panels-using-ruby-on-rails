class Business::AssetManagement::AssetTypesController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit, :update]
  layout "partner_application"

  def index
    @asset_types = @restaurant.asset_types.order("created_at DESC")
    @asset_types = @asset_types.where("name LIKE ? ", "%#{params[:keyword]}%") if params[:keyword].present? 
  end

  def new
    @asset_categories = @restaurant.asset_categories
    @asset_type = AssetType.new
  end

  def create
    @asset_type =  @restaurant.asset_types.new(asset_type_params)
    if @asset_type.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = @asset_type.errors.full_messages.join(", ")
    end
    redirect_to business_asset_management_asset_types_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    @asset_category = @restaurant.asset_categories
    @asset_type = AssetType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @asset_type = AssetType.find_by(id: params[:id])
    if @asset_type.update(asset_type_params.merge!(restaurant_id: @restaurant.id))
      flash[:success] = "Updated Successfully!"
      redirect_to business_asset_management_asset_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @asset_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @asset_type = AssetType.find_by(id: params[:id])
    if @asset_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_asset_management_asset_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @asset_type.errors.full_messages.join(", ")
    end
  end

  private

  def asset_type_params
    params.require(:asset_type).permit(:name, :restaurant_id, :asset_type_id, :asset_category_id).merge(created_by_id: @user.try(:id))
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
