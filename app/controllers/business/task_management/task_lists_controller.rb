class Business::TaskManagement::TaskListsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @task_lists = TaskList.where(restaurant_id: decode_token(params[:restaurant_id])).order("created_at desc")
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
 
    @task_list = TaskList.new
  end

  def create
    @restaurant = get_restaurant_data(decode_token(task_category_params[:restaurant_id]))
    pdf_url = upload_multipart_image(params[:task_list][:url], "task_lists",original_filename=nil)
    @task_list = TaskList.new(task_category_params.merge(restaurant_id: @restaurant.id,url: pdf_url))
    if @task_list.save
      flash[:success] = "Created Successfully!"
      redirect_to  business_task_management_restaurant_task_lists_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_list.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    # @task_lists = @restaurant.task_lists
    @task_list = TaskList.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    upload_check = task_category_params[:checkbox_check] == "true" ? false : true
    checkbox_check = task_category_params[:upload_check] == "true" ? false : true

    @task_list = TaskList.find_by(id: params[:id])
    unless params[:task_list][:url].blank?
      pdf_url = upload_multipart_image(params[:task_list][:url], "tasks_lists", original_filename=nil)
      task_category_updated_params = task_category_params.merge(restaurant_id: decode_token(params[:restaurant_id]),url: pdf_url)
    else
      task_category_updated_params = task_category_params.merge(restaurant_id: decode_token(params[:restaurant_id]))
    end
    if @task_list.update(task_category_updated_params.merge(checkbox_check: checkbox_check, upload_check: upload_check))
      flash[:success] = "Updated Successfully!"
      redirect_to  business_task_management_restaurant_task_lists_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_list.errors.full_messages.join(", ")
    end
  end

  def destroy
    @task_list = TaskList.find_by(id: params[:id])
    if @task_list.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to  business_task_management_restaurant_task_lists_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_list.errors.full_messages.join(", ")
    end
  end

  def find_country_based_branch
    @task_types = []
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    # @branch_ids = @restaurant.branches.where(country: params[:country_name]).ids
    @branches = Branch.where(id: @user&.user_detail&.location&.split(",")&.map(&:to_i))
  end

  def find_branch_based_task_type
    @task_types = []
    @asset_type = TaskList.find_by_id(params[:id])
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

  def find_task_activity_based_task_category
    task_category = TaskCategory.find_by_id(params[:task_category_id])
    @task_activities = task_category.task_activities rescue []
  end

  def find_task_sub_category_based_task_category
    task_category = TaskCategory.find_by_id(params[:task_category_id])
    @task_sub_categories = task_category.task_sub_categories rescue []
  end



  private

  def task_category_params

    params.require(:task_list).permit(:restaurant_id, :name, :task_type_id, :task_category_id, :task_sub_category_id, :task_activity_id, :created_by_id, :time_to,:enable, :checkbox_check, :upload_check,  :time_from, :location => [] ,:country_ids => [])
  end
end
