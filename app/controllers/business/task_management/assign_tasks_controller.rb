class Business::TaskManagement::AssignTasksController < ApplicationController
	before_action :authenticate_business
  layout "partner_application"

  def dashboard
  end

  def index
    @assign_tasks = AssignTask.where(restaurant_id: params[:restaurant_id]).order("created_at desc")
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @assign_task = AssignTask.new
  end

  def edit
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    # @task_lists = @restaurant.task_lists
    @assign_task = AssignTask.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @assign_task = AssignTask.find_by(id: params[:id])
    if @assign_task.update(edit_assign_params)
      flash[:success] = "Assign Task Created Successfully!"
    else
      flash[:error] = @assign_task.errors.full_messages.join(", ")
    end
    redirect_to business_task_management_restaurant_assign_tasks_path(restaurant_id: params[:assign_task][:restaurant_id])
  end

  def create
    @assign_task = AssignTask.new(assign_task_params)
    if @assign_task.save
      @assign_task.employee_ids.split(",").each do |employee_id|
        @assign_task.task_list_ids.split(",").each do |task_id|
          EmployeeAssignTask.create(assign_task_id: @assign_task.id,employee_id: employee_id,task_list_id: task_id,assign_date_time: @assign_task.assign_date_time)
        end
      end
      flash[:success] = "Assign Task Created Successfully!"
    else
      flash[:error] = @assign_task.errors.full_messages.join(", ")
    end
    redirect_to business_task_management_restaurant_assign_tasks_path(restaurant_id: params[:assign_task][:restaurant_id])
  end

  def find_country_based_branch
    @task_types = []
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.where(country: params[:country_name])
  end

  def find_designation_based_department
    departments = Department.where(id: params[:id])
    @designations = Designation.where(department_id: departments.ids)
  end

  def find_employee_based_designation
    designations = Designation.where(id: params[:id])
    @employees = User.joins(user_detail: {department: :designations}).where(designations: {id: designations.ids})
  end

  def destroy
    @task_list = AssignTask.find_by(id: params[:id])
    if @task_list.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to  business_task_management_restaurant_assign_tasks_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @task_list.errors.full_messages.join(", ")
    end
  end

  def find_task_list_based_branch
    task_list_ids = []
    branches = Branch.where(id: params[:branch_ids]).map(&:id)
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @restaurant.task_lists.each do |task_list|
      location = JSON task_list.location rescue []
      task_list_ids << task_list.id unless (location.map(&:to_s) & branches.map(&:to_s)).blank?
    end
    @task_lists = TaskList.where(id: task_list_ids.flatten)
  end

  private
  def assign_task_params
    params[:assign_task][:country_ids] = params[:assign_task][:country_ids].join(",") if params[:assign_task][:country_ids].present?
    params[:assign_task][:branch_ids] = params[:assign_task][:branch_ids].join(",") if params[:assign_task][:branch_ids].present?
    params[:assign_task][:department_ids] = params[:assign_task][:department_ids].join(",") if params[:assign_task][:department_ids].present?
    params[:assign_task][:designation_ids] = params[:assign_task][:designation_ids].join(",") if params[:assign_task][:designation_ids].present?
    params[:assign_task][:employee_ids] = params[:assign_task][:employee_ids].join(",") if params[:assign_task][:employee_ids].present?
    params[:assign_task][:task_list_ids] = params[:assign_task][:task_list_ids].join(",") if params[:assign_task][:task_list_ids].present?
    params.require(:assign_task).permit(:country_ids, :branch_ids, :department_ids, :designation_ids, :employee_ids, :task_list_ids, :restaurant_id, :assign_date, :assign_date_time, :created_by_id)
  end

  def edit_assign_params
   params[:assign_task][:country_ids] = params[:assign_task][:country_ids].join(",") if params[:assign_task][:country_ids].present?
    params[:assign_task][:branch_ids] = params[:assign_task][:branch_ids].join(",") if params[:assign_task][:branch_ids].present?
    params[:assign_task][:department_ids] = params[:assign_task][:department_ids].join(",") if params[:assign_task][:department_ids].present?
    params[:assign_task][:designation_ids] = params[:assign_task][:designation_ids].join(",") if params[:assign_task][:designation_ids].present?
    params[:assign_task][:employee_ids] = params[:assign_task][:employee_ids].join(",") if params[:assign_task][:employee_ids].present?
    params[:assign_task][:task_list_ids] = params[:assign_task][:task_list_ids].join(",") if params[:assign_task][:task_list_ids].present?
    params.require(:assign_task).permit(:country_ids, :branch_ids, :department_ids, :designation_ids, :employee_ids, :task_list_ids, :restaurant_id, :assign_date, :assign_date_time, :created_by_id, :country_ids, :branch_ids, :department_ids, :designation_ids, :employee_ids, :task_list_ids)
  end
end
