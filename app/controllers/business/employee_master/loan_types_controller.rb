class Business::EmployeeMaster::LoanTypesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @loan_types = LoanType.all
  end

  def new
    @loan_type = LoanType.new
  end

  def create
    @loan_type = LoanType.new(loan_type_params)
    if @loan_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_employee_master_loan_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @loan_type.errors.full_messages.join(", ")
    end
  end

  def edit
    @loan_type = LoanType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @loan_type = LoanType.find_by(id: params[:id])
    if @loan_type.update(loan_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_employee_master_loan_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @loan_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @loan_type = LoanType.find_by(id: params[:id])
    if @loan_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_employee_master_loan_types_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @loan_type.errors.full_messages.join(", ")
    end
  end

  private

  def loan_type_params
    params.require(:loan_type).permit(:name, :restaurant_id)
  end
end

