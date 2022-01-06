class Business::EmployeeMaster::DesignationsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @designations = @restaurant.designations
  end

  def new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @restaurant_id = params[:restaurant_id]
    @designation = Designation.new
    @departments = @restaurant.departments
  end

  def create
    @restaurant_id = params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @designation = @restaurant.designations.new(designation_params)
    if @designation.save
      flash[:success] = "Created Successfully!"
      redirect_to business_employee_master_restaurant_designations_path(@restaurant_id)
    else
      flash[:error] = @designation.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @restaurant_id = params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @designation = @restaurant.designations.find_by(id: params[:id])
    @departments = Department.all
    render layout: "partner_application"
  end

  def update
    @restaurant_id = params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @designation = @restaurant.designations.find_by(id: params[:id])
    if @designation.update(designation_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_employee_master_restaurant_designations_path(@restaurant_id)
    else
      flash[:error] = @designation.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @restaurant_id = params[:restaurant_id]
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @designation = @restaurant.designations.find_by(id: params[:id])
    if @designation.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = @designation.errors.full_messages.join(", ")
    end
    redirect_to business_employee_master_restaurant_designations_path(@restaurant_id)
  end

  private

  def designation_params
    params.require(:designation).permit(:id, :name, :department_id)
  end
end
