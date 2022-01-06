class Business::EmployeeMaster::AssetCategoriesController < ApplicationController
    before_action :authenticate_business
    layout "partner_application"
  
    def index
      @asset_categories = AssetCategory.all
    end
  
    def new
       @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
       @asset_types = @restaurant.asset_types
      @asset_category = AssetCategory.new
    end
  
    def create
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @asset_category = @restaurant.asset_categories.new(asset_category_params)
      if @asset_category.save
        flash[:success] = "Created Successfully!"
        redirect_to  business_employee_master_asset_categories_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @asset_category.errors.full_messages.join(", ")
      end
    end
  
    def edit
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @asset_types = @restaurant.asset_types
      @asset_category = AssetCategory.find_by(id: params[:id])
      render layout: "partner_application"
    end
  
    def update
      @asset_category = AssetCategory.find_by(id: params[:id])
      if @asset_category.update(asset_category_params)
        flash[:success] = "Updated Successfully!"
        redirect_to  business_employee_master_asset_categories_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @asset_category.errors.full_messages.join(", ")
      end
    end
  
    def destroy
      @asset_category = AssetCategory.find_by(id: params[:id])
      if @asset_category.destroy
        flash[:success] = "Deleted Successfully!"
        redirect_to  business_employee_master_asset_categories_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @asset_category.errors.full_messages.join(", ")
      end
    end
  
    private
  
    def asset_category_params
      params.require(:asset_category).permit(:name, :restaurant_id,:asset_type_id).merge(created_by_id: @user&.id)
    end
  end
  
  