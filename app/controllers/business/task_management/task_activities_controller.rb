class Business::TaskManagement::TaskActivitiesController < ApplicationController
    before_action :authenticate_business
    layout "partner_application"
  
    def index
      @task_activities = TaskActivity.where(restaurant_id: decode_token(params[:restaurant_id])).order("created_at desc")
    end
  
    def new
       @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
   
      @task_activity = TaskActivity.new
    end
  
    def create
      @restaurant = get_restaurant_data(decode_token(task_activity_params[:restaurant_id]))
      @task_activity = TaskActivity.new(task_activity_params.merge(restaurant_id: @restaurant.id))
      if @task_activity.save
        flash[:success] = "Created Successfully!"
        redirect_to  business_task_management_restaurant_task_activities_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @task_activity.errors.full_messages.join(", ")
        render :new
      end
    end
  
    def edit
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      # @task_categories = @restaurant.task_categories
      @task_activity = TaskActivity.find_by(id: params[:id])
      render layout: "partner_application"
    end
  
    def update
      @task_activity = TaskActivity.find_by(id: params[:id])
      if @task_activity.update(task_activity_params.merge(restaurant_id: decode_token(params[:restaurant_id])))
        flash[:success] = "Updated Successfully!"
        redirect_to  business_task_management_restaurant_task_activities_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @task_activity.errors.full_messages.join(", ")
      end
    end
  
    def destroy
      @task_activity = TaskActivity.find_by(id: params[:id])
      if @task_activity.destroy
        flash[:success] = "Deleted Successfully!"
        redirect_to  business_task_management_restaurant_task_activities_path(restaurant_id: params[:restaurant_id])
      else
        flash[:error] = @task_activity.errors.full_messages.join(", ")
      end
    end
  
    def find_country_based_branch
      @task_types = []
      @task_categories = []
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @branches = @restaurant.branches.where(country: params[:country_name])
    end
  
    def find_branch_based_task_type
      @task_types = []
      @asset_type = TaskActivity.find_by_id(params[:id])
      @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @restaurant.task_types.each do |task_type|
        location = JSON task_type.location rescue []
        @task_types << task_type unless (location & params[:location_ids]).flatten.blank?
      end
      @task_types.flatten   
    end

    def find_task_category_based_task_type
      task_type = TaskType.find_by_id(params[:task_type_id])
      @task_categories = task_type.task_categories
    end
  
    private
  
    def task_activity_params
      params.require(:task_activity).permit(:name, :restaurant_id, :task_type_id, :task_category_id, :created_by_id, :country_ids => [], :location => [])
    end
  end
  