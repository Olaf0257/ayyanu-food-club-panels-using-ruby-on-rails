class Business::PaymentMethodsController < ApplicationController
  before_action :authenticate_business
  before_action :get_branch

  def index
    @payment_methods = PaymentMethod.all
    render layout: "partner_application"
  end

  def new
    @payment_method = PaymentMethod.new
    render layout: "partner_application"
  end

  def create
    @payment_method = PaymentMethod.new(payment_method_params)
    if @payment_method.save
      flash[:success] = "Created Successfully!"
      redirect_to business_payment_methods_path(params[:restaurant_id])
    else
      flash[:error] = @payment_method.errors.full_messages.join(", ")
    end
  end

  def edit
    @payment_method = PaymentMethod.find_by(id: params[:id])
    render layout: "partner_application"
  end

  def update
    @payment_method = PaymentMethod.find_by(id: params[:id])
    if @payment_method.update(payment_method_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_payment_methods_path(params[:restaurant_id])
    else
      flash[:error] = @payment_method.errors.full_messages.join(", ")
    end
  end

  def destroy
    @payment_method = PaymentMethod.find_by(id: params[:id])
    if @payment_method.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_payment_methods_path(params[:restaurant_id])
    else
      flash[:error] = @payment_method.errors.full_messages.join(", ")
    end
  end

  def get_branch
    restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = restaurant.branch
  end

  private

  def payment_method_params
    params.require(:payment_method).permit(:id, :name, :is_enabled, :created_by_id, :last_updated_by_id)
  end
end
