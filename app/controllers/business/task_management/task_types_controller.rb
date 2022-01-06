class Business::TaskManagement::TaskTypesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @task_types = TaskType.where(restaurant_id: decode_token(params[:restaurant_id])).order("created_at desc")
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
 
    @task_type = TaskType.new
  end

  def create
    @task_type = TaskType.new(task_type_params.merge(restaurant_id: decode_token(params[:restaurant_id])))
    if @task_type.save
      flash[:success] = "Created Successfully!"
      redirect_to  business_task_management_restaurant_task_types_path(restaurant_id: params[:restaurant_id])
    else
      # @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
      flash[:error] = @task_type.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    @task_types = @restaurant.task_types
    @task_type = TaskType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @task_type = TaskType.find_by(id: params[:id])
    if @task_type.update(task_type_params)
      flash[:success] = "Updated Successfully!"
       redirect_to  business_task_management_restaurant_task_types_path(restaurant_id: params[:restaurant_id])
    else
      @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
      flash[:error] = @task_type.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @task_type = TaskType.find_by(id: params[:id])
    if @task_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to  business_task_management_restaurant_task_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_type.errors.full_messages.join(", ")
      redirect_to  business_task_management_restaurant_task_types_path(restaurant_id: params[:restaurant_id])
    end
  end

  def find_country_based_branch
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  private

  def task_type_params
    params.require(:task_type).permit(:name, :restaurant_id, :created_by_id, :location => [],:country_ids => [])
  end
end
