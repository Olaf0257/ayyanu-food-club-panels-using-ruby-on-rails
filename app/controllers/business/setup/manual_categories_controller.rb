class Business::Setup::ManualCategoriesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @manual_categories = @restaurant.manual_categories.all.order("created_at DESC")
    @manual_categories = @manual_categories.where("name LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @manual_category = ManualCategory.new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @manual_category = @restaurant.manual_categories.new(manual_category_params)
    @manual_category.restaurant_id = @restaurant.id
    if @manual_category.save
      flash[:success] = "Created Successfully!"
      redirect_to new_business_setup_restaurant_manual_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual_category.errors.full_messages.join(", ")
    end
  end

  def edit
    @manual_category = ManualCategory.find_by(id: params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    render layout: "partner_application"
  end

  def update
    @manual_category = ManualCategory.find_by(id: params[:id])
    if @manual_category.update(manual_category_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_restaurant_manual_categories_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual_category.errors.full_messages.join(", ")
    end
  end

  def destroy
    @manual_category = ManualCategory.find_by(id: params[:id])
    if @manual_category.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_restaurant_manual_categories_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual_category.errors.full_messages.join(", ")
    end
  end

  private

  def manual_category_params
  params.require(:manual_category).permit(:name).merge(created_by_id: @user.try(:id))
  end
end
