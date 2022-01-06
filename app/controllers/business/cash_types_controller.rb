class Business::CashTypesController < ApplicationController
  before_action :authenticate_business
  before_action :get_branch

  def index
    @cash_types = CashType.all
    render layout: "partner_application"
  end

  def new
    @cash_type = @restaurant.cash_types.new
    render layout: "partner_application"
  end

  def create
    @cash_type = @restaurant.cash_types.new(cash_type_params)
    if @cash_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_cash_types_path(params[:restaurant_id])
    else
      flash[:error] = @cash_type.errors.full_messages.join(", ")
    end
  end

  def edit
    @cash_type = CashType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @cash_type = CashType.find_by(id: params[:id])
    if @cash_type.update(cash_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_cash_types_path(params[:restaurant_id])
    else
      flash[:error] = @cash_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @cash_type = CashType.find_by(id: params[:id])
    if @cash_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_cash_types_path(params[:restaurant_id])
    else
      flash[:error] = @cash_type.errors.full_messages.join(", ")
    end
  end

  def get_branch
    @restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = @restaurant.branch
  end

  private

  def cash_type_params
    params.require(:cash_type).permit(:id, :amount, :pos_cash_type, :converted_amount, :is_enabled, :created_by_id, :last_updated_by_id)
  end
end
