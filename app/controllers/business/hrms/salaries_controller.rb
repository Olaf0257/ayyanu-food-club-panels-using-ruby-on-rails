class Business::Hrms::SalariesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def index
    @salaries = Salary.where(restaurant_id: params[:restaurant_id]).all.order("created_at desc")
    render layout: "partner_application"
  end

  def new
    user_ids = find_employees(params)
    ids = Salary.all.map(&:user_id)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).where.not(id: ids).order("created_at desc")
    @salary = Salary.new
    # @salary.build_family_details
    render layout: "partner_application"
  end

  def create
    salary = Salary.new(salary_params)
    if salary.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = salary.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_salaries_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @salary = Salary.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @salary = Salary.find_by(id: params[:id])
    if @salary.update(salary_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_hrms_salaries_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @salary.errors.full_messages.join(", ")
    end
  end

  def destroy
    @salary = Salary.find_by(id: params[:id])
    if @salary.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_salaries_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @salary.errors.full_messages.join(", ")
    end
  end

  def get_user_detail
    @user = User.find_by_id(params[:user_id])
  end

  private

  def salary_params
    params.require(:salary).permit(:basic_salary, :gosi_percentage, :hiring_fees_deduction, :indemnity_days, :address, :full_hra, :full_conveyance, :full_da, :full_special_allowence, :monthly_ctc, :annual_ctc, :user_id, :housing_allowance, :transportation_allowance, :meal_allowance, :mobile_allowance, :visa_charges, :lmra_charges, :family_visa_charges, :health_check_charges, :restaurant_id)
  end
end
