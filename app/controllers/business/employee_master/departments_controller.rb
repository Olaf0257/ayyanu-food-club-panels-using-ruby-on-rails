class Business::EmployeeMaster::DepartmentsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant_id =params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @departments = @restaurant.departments
  end

  def new
    @restaurant_id =params[:restaurant_id]
    @department = Department.new
  end

  def create
    @restaurant_id =params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @department =  @restaurant.departments.new(department_params)
    if @department.save
      flash[:success] = "Created Successfully!"
      redirect_to business_employee_master_restaurant_departments_path(@restaurant_id)
    else
      flash[:error] = @department.errors.full_messages.join(", ")
    end
  end

  def edit
    @restaurant_id =params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @department = Department.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @restaurant_id =params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @department = Department.find_by(id: params[:id])
    @department.restaurant_id = @restaurant.id
    if @department.update(department_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_employee_master_restaurant_departments_path(@restaurant_id)
    else
      flash[:error] = @department.errors.full_messages.join(", ")
    end
  end

  def destroy
    @restaurant_id =params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @department = @restaurant.departments.find_by(id: params[:id])
    if @department.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_employee_master_restaurant_departments_path(@restaurant_id)
    else
      flash[:error] = @department.errors.full_messages.join(", ")
    end
  end

  private

  def department_params
    params.require(:department).permit(:id, :name)
  end
end
