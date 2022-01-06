class Business::Setup::ManualsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @manuals = @restaurant.manuals.all.order("created_at DESC")
    @manuals = @manuals.joins(:manual_category).where("manual_categories.name LIKE ? OR manuals.name LIKE ?", "%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @manual = Manual.new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @manual = @restaurant.manuals.new(manual_params)
    @manual.restaurant_id = @restaurant.id
    if @manual.save
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_restaurant_manuals_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual.errors.full_messages.join(", ")
    end
  end

  def edit
    @manual = Manual.find_by(id: params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    render layout: "partner_application"
  end

  def update
    @manual = Manual.find_by(id: params[:id])
    if @manual.update(manual_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_restaurant_manuals_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual.errors.full_messages.join(", ")
    end
  end

  def destroy
    @manual = Manual.find_by(id: params[:id])
    if @manual.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_restaurant_manuals_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @manual.errors.full_messages.join(", ")
    end
  end

  private

  def manual_params
  params.require(:manual).permit(:name, :manual_category_id).merge(created_by_id: @user.try(:id))
  end
end
