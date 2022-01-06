class Business::Hrms::LoanSettlementsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def show
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan_settlement = LoanSettlement.find_by(id: params[:id])
    @loan = @loan_settlement.loan
  end

  def index
    @loan_settlements = LoanSettlement.where(restaurant_id: params[:restaurant_id], status: Loan::STATUS[:approved]).all.order("created_at desc")
    render layout: "partner_application"
  end

  def new
    user_ids = find_employees(params)
    # ids = LoanSettlement.all.map(&:user_id)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan_settlement = LoanSettlement.new
    # @loan_settlement.build_family_details
    render layout: "partner_application"
  end

  def create
    loan_settlement = LoanSettlement.new(loan_settlement_params.merge(status: Loan::STATUS[:pending]))
    if loan_settlement.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = loan_settlement.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_loan_settlements_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan_settlement = LoanSettlement.find_by(id: params[:id])
    @loan = @loan_settlement.loan
    render layout: "partner_application"
  end

  def update
    @loan_settlement = LoanSettlement.find_by(id: params[:id])
    status = @loan_settlement.status
    if @loan_settlement.update(loan_settlement_params.merge(status: Loan::STATUS[:pending]))
      flash[:success] = "Updated Successfully!"

      if status == "rejected"
        redirect_to reject_loan_settelment_business_hrms_loan_settlements_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_hrms_loan_settlements_path(restaurant_id: params[:restaurant_id])
      end
    else
      flash[:error] = @loan_settlement.errors.full_messages.join(", ")
    end
  end

  def destroy
    @loan_settlement = LoanSettlement.find_by(id: params[:id])
    if @loan_settlement.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_loan_settlements_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @loan_settlement.errors.full_messages.join(", ")
    end
  end

  def approve_loan_settelment
    loan = LoanSettlement.find_by_id(params[:id])
    loan.update(status: Loan::STATUS[:approved])
    flash[:success] = "Loan Approved!"
    redirect_to review_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

  def get_user_detail
    @user = User.find_by_id(params[:user_id])
  end

  def reject_loan_settelment
    loan = LoanSettlement.find_by_id(params[:loan_settlement_id])
    loan.update(status: Loan::STATUS[:rejected], rejected_reason: params[:rejected_reason])
    flash[:success] = "Loan Rejected!"
    redirect_to review_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

  def loan_list
    @loans = Loan.where(user_id: params[:id], status: Loan::STATUS[:approved])
  end

  def loan_details
    @loan = Loan.find_by_id(params[:id])
  end

  private

  def loan_settlement_params
    params.require(:loan_settlement).permit(:remaining_amount, :payment_mode, :when_to_settle_date, :user_id, :restaurant_id, :loan_id)
  end
end
