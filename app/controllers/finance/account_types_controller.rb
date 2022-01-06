class Finance::AccountTypesController < ApplicationController
  before_action :authenticate_business
  before_action :find_restaurant, only: [:index, :new, :create, :edit]
  layout "partner_application"

  def index
    @account_types = AccountType.search(params[:keyword]).where(restaurant: @restaurant).order(id: :desc).paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def new
    @account_type = @restaurant.account_types.new
  end

  def create
    @account_type = @restaurant.account_types.new(account_type_params)
    if @account_type.save
      flash[:success] = "Created Successfully!"
      redirect_to finance_restaurant_account_types_path
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
      redirect_to finance_restaurant_account_types_path
    else
      flash[:error] = @account_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @account_type = AccountType.find_by(id: params[:id])
    if @account_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to finance_restaurant_account_types_path
    else
      flash[:error] = @account_type.errors.full_messages.join(", ")
    end
  end

  private

  def account_type_params
    params.require(:account_type).permit(:id, :name, :restaurant_id).merge(updated_by_id: @user.try(:id))
  end

  def find_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
  end
end
