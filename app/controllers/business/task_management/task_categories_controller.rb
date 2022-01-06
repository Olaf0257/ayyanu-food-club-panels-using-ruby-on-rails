class Business::TaskManagement::TaskCategoriesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @task_categories = TaskCategory.where(restaurant_id: decode_token(params[:restaurant_id])).order("created_at desc")
  end

  def new
     @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
 
    @task_category = TaskCategory.new
  end

  def create
    @restaurant = get_restaurant_data(decode_token(task_category_params[:restaurant_id]))
    @task_category = TaskCategory.new(task_category_params.merge(restaurant_id: @restaurant.id))
    if @task_category.save
      flash[:success] = "Created Successfully!"
      redirect_to  business_task_management_restaurant_task_categories_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_category.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    # @task_categories = @restaurant.task_categories
    @task_category = TaskCategory.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @task_category = TaskCategory.find_by(id: params[:id])
    if @task_category.update(task_category_params.merge(restaurant_id: decode_token(params[:restaurant_id])))
      flash[:success] = "Updated Successfully!"
      redirect_to  business_task_management_restaurant_task_categories_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_category.errors.full_messages.join(", ")
    end
  end

  def destroy
    @task_category = TaskCategory.find_by(id: params[:id])
    if @task_category.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to  business_task_management_restaurant_task_categories_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_category.errors.full_messages.join(", ")
    end
  end

  def find_country_based_branch
    @task_types = []
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  def find_branch_based_task_type
    @task_types = []
    @asset_type = TaskCategory.find_by_id(params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @restaurant.task_types.each do |task_type|
      location = JSON task_type.location rescue []
      @task_types << task_type unless (location & params[:location_ids]).flatten.blank?
    end
    @task_types.flatten
  end

  private

  def task_category_params
    params.require(:task_category).permit(:category_name, :area, :restaurant_id, :task_type_id, :created_by_id, :location => [] ,:country_ids => [])
  end
end
