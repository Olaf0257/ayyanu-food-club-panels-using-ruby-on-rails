class Business::CurrencyTypesController < ApplicationController
  before_action :authenticate_business
  before_action :get_branch

  def index
    @currency_types = CurrencyType.all
    render layout: "partner_application"
  end

  def new
    @currency_type = CurrencyType.new
    render layout: "partner_application"
  end

  def create
    @currency_type = CurrencyType.new(currency_type_params)
    if @currency_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_currency_types_path(params[:restaurant_id])
    else
      flash[:error] = @currency_type.errors.full_messages.join(", ")
    end
  end

  def edit
    @currency_type = CurrencyType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @currency_type = CurrencyType.find_by(id: params[:id])
    if @currency_type.update(currency_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_currency_types_path(params[:restaurant_id])
    else
      flash[:error] = @currency_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @currency_type = CurrencyType.find_by(id: params[:id])
    if @currency_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_currency_types_path(params[:restaurant_id])
    else
      flash[:error] = @currency_type.errors.full_messages.join(", ")
    end
  end

  def get_branch
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = restaurant.branch
  end

  private

  def currency_type_params
    params.require(:currency_type).permit(:id, :currency, :amount,:is_enabled, :created_by_id, :last_updated_by_id)
  end
end
