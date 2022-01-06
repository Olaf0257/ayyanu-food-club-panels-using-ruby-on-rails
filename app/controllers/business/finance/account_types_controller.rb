class Business::Finance::AccountTypesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @account_types = AccountType.all
    @account_types = @account_types.where("name LIKE ? ", "%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @account_type = AccountType.new
  end

  def create
    @account_type = AccountType.new(account_type_params)
    if @account_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_finance_account_types_path
    else
      flash[:error] = @account_type.errors.full_messages.join(", ")
    end
  end

  def edit
    @account_type = AccountType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @account_type = AccountType.find_by(id: params[:id])
    if @account_type.update(account_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_finance_account_types_path
    else
      flash[:error] = @account_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @account_type = AccountType.find_by(id: params[:id])
    if @account_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_finance_account_types_path
    else
      flash[:error] = @account_type.errors.full_messages.join(", ")
    end
  end

  private

  def account_type_params
    params.require(:account_type).permit(:id, :name).merge(updated_by_id: @user.try(:id))
  end
end
