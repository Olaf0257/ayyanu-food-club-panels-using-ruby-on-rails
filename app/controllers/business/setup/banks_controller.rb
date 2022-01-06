class Business::Setup::BanksController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @banks = @restaurant.banks.all.order("created_at DESC")
    @countries = Country.where(id: @banks.pluck(:country_id).uniq).pluck(:name, :id).sort
    @banks = @banks.where(country_id: params[:country_id]) if params[:country_id].present?
    @banks = @banks.where("name LIKE ? OR account_number LIKE ? OR ifsc LIKE ? OR swift_code LIKE ? OR area LIKE ? OR iban LIKE?", "%#{params[:keyword]}%","%#{params[:keyword]}%","%#{params[:keyword]}%","%#{params[:keyword]}%","%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
  end

  def new
    @bank = Bank.new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @bank = Bank.new(bank_params)
    @banks.restaurant_id = @restaurant.id
    if @bank.save
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_banks_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @bank.errors.full_messages.join(", ")
    end
  end

  def edit
    @bank = Bank.find_by(id: params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    render layout: "partner_application"
  end

  def update
    @bank = Bank.find_by(id: params[:id])
    if @bank.update(bank_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_banks_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @bank.errors.full_messages.join(", ")
    end
  end

  def destroy
    @bank = Bank.find_by(id: params[:id])
    if @bank.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_banks_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @bank.errors.full_messages.join(", ")
    end
  end

  private

  def bank_params
    params.require(:bank).permit(:id, :name, :account_number, :swift_code, :ifsc, :iban, :address, :block, :road_no, :building, :floor, :additional_direction, :phone,:country_id, :area_id).merge(updated_by_id: @user.try(:id))
  end
end
