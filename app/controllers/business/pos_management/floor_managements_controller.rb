class Business::PosManagement::FloorManagementsController < ApplicationController
  before_action :authenticate_business

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    render layout: "partner_application"
  end

  def new
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
    pos_tables = PosTable.where(branch_id: params[:id], floor_name: params[:floor_name])
    if pos_tables.destroy_all
      flash[:success] = "Deleted Successfully!"
      redirect_to business_pos_management_floor_managements_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @cash_type.errors.full_messages.join(", ")
      redirect_to business_pos_management_floor_managements_path(restaurant_id: params[:restaurant_id])
    end
  end

  def get_branch
    @restaurant = Restaurant.find_by(id: decode_token(params[:restaurant_id]))
    @branch = @restaurant.branch
  end

  private

  def floor_management_params
    params.require(:cash_type).permit(:id, :amount, :pos_cash_type, :converted_amount, :is_enabled, :created_by_id, :last_updated_by_id)
  end
end
