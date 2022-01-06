class Business::OrderTypesController < ApplicationController
  before_action :authenticate_business
  before_action :get_branch

  def index
    @order_types = OrderType.all
    render layout: "partner_application"
  end

  def new
    @order_type = OrderType.new
    render layout: "partner_application"
  end

  def create
    @order_type = OrderType.new(order_type_params)
    if @order_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_order_types_path(params[:restaurant_id])
    else
      flash[:error] = @order_type.errors.full_messages.join(", ")
    end
  end

  def edit
    @order_type = OrderType.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @order_type = OrderType.find_by(id: params[:id])
    if @order_type.update(order_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_order_types_path(params[:restaurant_id])
    else
      flash[:error] = @order_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    @order_type = OrderType.find_by(id: params[:id])
    if @order_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_order_types_path(params[:restaurant_id])
    else
      flash[:error] = @order_type.errors.full_messages.join(", ")
    end
  end

  def get_branch
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = restaurant.branch
  end

  private

  def order_type_params
    params.require(:order_type).permit(:id, :name, :is_enabled, :created_by_id, :last_updated_by_id)
  end
end
