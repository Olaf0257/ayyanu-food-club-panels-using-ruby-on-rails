class Finance::AccountCategoriesController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit]
  layout "partner_application"

  def index
    @account_categories = AccountCategory.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @account_category = @restaurant.account_categories.new
    @account_types = @restaurant.account_types
  end

  def create
    @account_category = @restaurant.account_categories.new(account_category_params)
    if @account_category.save
      flash[:success] = "Created Successfully!"
      redirect_to finance_restaurant_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  def edit
    @account_category = AccountCategory.find_by(id: params[:id])
    @account_types = @restaurant.account_types
    render layout: "partner_application"
  end

  def update
    @account_category = AccountCategory.find_by(id: params[:id])
    if @account_category.update(account_category_params)
      flash[:success] = "Updated Successfully!"
      redirect_to finance_restaurant_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  def destroy
    @account_category = AccountCategory.find_by(id: params[:id])
    if @account_category.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to finance_restaurant_account_categories_path
    else
      flash[:error] = @account_category.errors.full_messages.join(", ")
    end
  end

  private

  def account_category_params
    params.require(:account_category).permit(:id, :name, :restaurant_id, :account_type_id).merge(updated_by_id: @user.try(:id))
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
