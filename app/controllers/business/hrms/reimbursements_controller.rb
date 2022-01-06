class Business::Hrms::ReimbursementsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"


  def dashboard
    render layout: "partner_application"
  end

  def index
    @reimbursements = Reimbursement.all.where(restaurant_id: params[:restaurant_id], status: Reimbursement::STATUS[:approved]).order(updated_at: :desc)
    render layout: "partner_application"
  end

  def new
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @reimbursement = Reimbursement.new
    # @reimbursement.build_family_details
    render layout: "partner_application"
  end

  def show
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @reimbursement = Reimbursement.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def create
    reimbursement = Reimbursement.new(reimbursement_params.merge(status: Reimbursement::STATUS[:pending]))
    if reimbursement.save
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = reimbursement.errors.full_messages.first.to_s
    end
    redirect_to business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
  end

  def edit
    user_ids = find_employees(params)
    @employees = User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    @reimbursement = Reimbursement.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @reimbursement = Reimbursement.find_by(id: params[:id])
    status = @reimbursement.status
    if @reimbursement.update(reimbursement_params.merge(status: Reimbursement::STATUS[:pending]))
      flash[:success] = "Updated Successfully!"
      # redirect_to business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
      if status == "rejected"
        redirect_to rejected_reimbursement_business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
      else
        redirect_to business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
      end
    else
      flash[:error] = @reimbursement.errors.full_messages.join(", ")
    end
  end

  def destroy
    @reimbursement = Reimbursement.find_by(id: params[:id])
    if @reimbursement.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])    else
      flash[:error] = @reimbursement.errors.full_messages.join(", ")
    end
  end

  def get_user_detail
    @user = User.find_by_id(params[:user_id])
  end

  def review_reimbursement
    @reimbursements = Reimbursement.all.where(restaurant_id: params[:restaurant_id], status: Reimbursement::STATUS[:pending]).order(updated_at: :desc)
    render layout: "partner_application"
  end

  def approve_reimbursement
    reimbursement = Reimbursement.find_by_id(params[:id])
    reimbursement.update(status: Reimbursement::STATUS[:approved])
    flash[:success] = "Reimbursement Approved!"
    redirect_to review_reimbursement_business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
  end

  def reject_reimbursement
    reimbursement = Reimbursement.find_by_id(params[:reimbursement_id])
    reimbursement.update(status: Reimbursement::STATUS[:rejected], rejected_reason: params[:rejected_reason])
    flash[:success] = "Reimbursement Rejected!"
    redirect_to review_reimbursement_business_hrms_reimbursements_path(restaurant_id: params[:restaurant_id])
  end

  def rejected_reimbursement
    @reimbursements = Reimbursement.all.where(restaurant_id: params[:restaurant_id], status: Reimbursement::STATUS[:rejected]).order(updated_at: :desc)
  end

  private

  def reimbursement_params
    params.require(:reimbursement).permit(:reimbursement_type_id, :reimbursement_date, :amount, :remarks, :status, :user_id, :restaurant_id, :created_by_id, :rejected_reason)
  end
end
