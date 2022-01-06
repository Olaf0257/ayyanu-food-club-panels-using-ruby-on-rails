class Business::EmployeeMaster::ReimbersmentsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @reimbersments = ReimbursementType.all
  end

  def new
    @reimbersment = ReimbursementType.new
  end

  def create
    @reimbersment = ReimbursementType.new(reimbersment_params)
    if @reimbersment.save
      flash[:success] = "Created Successfully!"
      redirect_to business_employee_master_reimbersments_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @reimbersment.errors.full_messages.join(", ")
    end
  end

  def edit
    @reimbersment = ReimbursementType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @reimbersment = ReimbursementType.find_by(id: params[:id])
    if @reimbersment.update(reimbersment_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_employee_master_reimbersments_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @reimbersment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @reimbersment = ReimbursementType.find_by(id: params[:id])
    if @reimbersment.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_employee_master_reimbersments_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @reimbersment.errors.full_messages.join(", ")
    end
  end

  private

  def reimbersment_params
    params.require(:reimbursement_type).permit(:name)
  end
end
