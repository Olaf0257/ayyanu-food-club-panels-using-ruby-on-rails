class Business::Finance::AccountCategoriesController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @account_categories = AccountCategory.all
    @account_categories = @account_categories.where("name LIKE ? ", "%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @account_category = AccountCategory.new
  end

  def create
    @account_category = AccountCategory.new(account_category_params)
    if @account_category.save
      flash[:success] = "Created Successfully!"
      redirect_to business_finance_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  def edit
    @account_category = AccountCategory.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @account_category = AccountCategory.find_by(id: params[:id])
    if @account_category.update(account_category_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_finance_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  def destroy
    @account_category = AccountCategory.find_by(id: params[:id])
    if @account_category.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_finance_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  private

  def account_category_params
    params.require(:account_category).permit(:id, :name, :account_type_id).merge(updated_by_id: @user.try(:id))
  end
end
