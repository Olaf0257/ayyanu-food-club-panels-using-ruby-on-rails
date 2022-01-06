class Business::Setup::CardTypesController < ApplicationController
  before_action :authenticate_business
  before_action :find_card_type_and_restaurant, only: [:edit, :update, :destroy]
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @card_types = @restaurant.card_types
    @card_types = @card_types.where("name LIKE ? ", "%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @card_type = CardType.new
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @card_type = @restaurant.card_types.new(card_type_params)
    if @card_type.save
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_restaurant_card_types_path(params[:restaurant_id]) 
    else
      flash[:error] = @card_type.errors.full_messages.join(", ")
    end
  end

  def edit
    render layout: "partner_application"
  end

  def update
    if @card_type.update(card_type_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_restaurant_card_types_path(params[:restaurant_id]) 
    else
      flash[:error] = @card_type.errors.full_messages.join(", ")
    end
  end

  def destroy
    if @card_type.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_restaurant_card_types_path(params[:restaurant_id]) 
    else
      flash[:error] = @card_type.errors.full_messages.join(", ")
    end
  end

  private

  def find_card_type_and_restaurant
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @card_type = @restaurant.card_types.find_by(id: params[:id])
   end

  def card_type_params
    params.require(:card_type).permit(:id, :name).merge(updated_by_id: @user.try(:id))
  end
end
