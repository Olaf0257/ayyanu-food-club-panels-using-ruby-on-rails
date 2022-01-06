class Business::Hrms::LoansController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def index
    @loans = Loan.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:approved]).all.order("created_at desc")
    render layout: "partner_application"
  end

  def new
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan = Loan.new
    render layout: "partner_application"
  end

  def create
    salary = Loan.new(salary_params.merge(status: Loan::STATUS[:pending]))
    if salary.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = salary.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

  def show
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan = Loan.find_by(id: params[:id])
  end

  def edit
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan = Loan.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @salary = Loan.find_by(id: params[:id])
    status = @salary.status
    if @salary.update(salary_params.merge(status: Loan::STATUS[:pending]))
      flash[:success] = "Updated Successfully!"
      if status == "rejected"
        redirect_to rejected_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_hrms_loans_path(restaurant_id: params[:restaurant_id])
      end
    else
      flash[:error] = @salary.errors.full_messages.join(", ")
    end
  end

  def destroy
    @salary = Loan.find_by(id: params[:id])
    if @salary.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_loans_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @salary.errors.full_messages.join(", ")
    end
  end

  def review_loan
    @loans = Loan.all.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:pending]).order(updated_at: :desc)
    @loan_revises = LoanRevise.all.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:pending]).order("created_at desc")
    @loan_settlements = LoanSettlement.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:pending]).all.order("created_at desc")
    render layout: "partner_application"
  end

  def approve_loan
    loan = Loan.find_by_id(params[:id])
    loan.update(status: Loan::STATUS[:approved])
    flash[:success] = "Loan Approved!"
    redirect_to review_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

  def reject_loan
    loan = Loan.find_by_id(params[:loan_id])
    loan.update(status: Loan::STATUS[:rejected], rejected_reason: params[:rejected_reason])
    flash[:success] = "Loan Rejected!"
    redirect_to review_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

  def rejected_loan
    @loans = Loan.all.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:rejected]).order(updated_at: :desc)
    @loan_revises = LoanRevise.all.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:rejected]).order(updated_at: :desc)
    @loan_settlements = LoanSettlement.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:rejected]).all.order("created_at desc")
  end

  def department_designation
    @user = User.find_by_id(params[:id])
  end

  private

  def salary_params
    params.require(:loan).permit(:user_id, :department, :designation, :loan_date, :amount, :deducted_from, :interest_rate, :created_date, :installments, :loan_type_id, :restaurant_id, :account_number)
  end
end
