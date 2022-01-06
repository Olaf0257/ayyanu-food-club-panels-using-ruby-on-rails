class Business::Hrms::LoanRevisesController < ApplicationController
before_action :authenticate_business
layout "partner_application"

	def dashboard
		render layout: "partner_application"
	end

	def index
		@loan_revises = LoanRevise.all.where(status: Loan::STATUS[:approved]).order("created_at desc")
		render layout: "partner_application"
	end

	def new
		user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
		@loan_revise = LoanRevise.new
		render layout: "partner_application"
	end

	def create
		loan_revise = LoanRevise.new(loan_revise_params.merge(status: Loan::STATUS[:pending]))
		if loan_revise.save
			flash[:success] = "Created Successfully!"
		else
			flash[:error] = loan_revise.errors.full_messages.first.to_s
		end
		redirect_to business_hrms_loan_revises_path(restaurant_id: params[:restaurant_id])
	end

	def edit
		user_ids = find_employees(params)
		@employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
		@loan_revise = LoanRevise.find_by(id: params[:id])
		@loan = @loan_revise.loan
		render layout: "partner_application"
	end

	def update
		@loan_revise = LoanRevise.find_by(id: params[:id])
		status = @loan_revise.status
		if @loan_revise.update(loan_revise_params.merge(status: Loan::STATUS[:pending]))
			flash[:success] = "Updated Successfully!"

			if status == "rejected"
        redirect_to rejected_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_hrms_loan_revises_path(restaurant_id: params[:restaurant_id])
      end
		else
			flash[:error] = @loan_revise.errors.full_messages.join(", ")
		end
	end

	def destroy
		@loan_revise = LoanRevise.find_by(id: params[:id])
		if @loan_revise.destroy
			flash[:success] = "Deleted Successfully!"
			redirect_to business_hrms_loan_revises_path(restaurant_id: params[:restaurant_id])
		else
		  flash[:error] = @loan_revise.errors.full_messages.join(", ")
		end
	end

	def show
		user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @loan_revise = LoanRevise.find_by(id: params[:id])
    @loan = @loan_revise.loan
	end

	def approve_loan_revise
    loan = LoanRevise.find_by_id(params[:id])
    loan.update(status: Loan::STATUS[:approved])
    flash[:success] = "Loan Approved!"
    redirect_to review_loan_business_hrms_loans_path(restaurant_id: params[:restaurant_id])
  end

	def get_user_detail
		@user = User.find_by_id(params[:user_id])
	end

	def reject_loan_revise
    loan = LoanRevise.find_by_id(params[:revise_loan_id])
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

	def loan_revise_params
		params.require(:loan_revise).permit(:topup_amount, :loan_period, :new_interest_rate, :created_by_id, :restaurant_id, :loan_id, :user_id)
	end
end