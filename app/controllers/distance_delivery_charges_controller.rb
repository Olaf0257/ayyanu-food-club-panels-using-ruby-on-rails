class DistanceDeliveryChargesController < ApplicationController
  before_action :require_admin_logged_in

  def index
    if @admin.class.name == "SuperAdmin"
      @countries = Country.where(id: (DistanceDeliveryCharge.pluck(:country_id) + DeliveryCharge.pluck(:country_id)).uniq).pluck(:name, :id).sort
      @searched_country_id = params[:searched_country_id].presence || 15
      @distance_delivery_charges = DistanceDeliveryCharge.where(country_id: @searched_country_id)
      @delivery_charge = DeliveryCharge.find_by(country_id: @searched_country_id)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @distance_delivery_charges = DistanceDeliveryCharge.all.where(country_id: country_id)
      @delivery_charge = DeliveryCharge.find_by(country_id: country_id)
    end

    @charge = DistanceDeliveryCharge.new

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.csv { send_data @distance_delivery_charges.delivery_charges_list_csv(@delivery_charge), filename: "delivery_charges_list.csv" }
    end
  end

  def create
    new_range = params[:distance_delivery_charge][:min_distance].to_f...params[:distance_delivery_charge][:max_distance].to_f

    if @admin.class.name == "SuperAdmin"
      @overlap = DistanceDeliveryCharge.overlapping_range(new_range, nil, params[:distance_delivery_charge][:country_id])
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @overlap = DistanceDeliveryCharge.overlapping_range(new_range, nil, country_id)
    end

    if @overlap
      flash[:error] = "Range already present"
    else
      @charge = DistanceDeliveryCharge.new(delivery_charge_params)

      if @admin.class.name == "SuperAdmin"
        @charge.update(country_id: params[:distance_delivery_charge][:country_id])
      else
        country_id = @admin.class.find(@admin.id)[:country_id]
        @charge.update(country_id: country_id)
      end

      if @charge.save
        flash[:success] = "Successfully Created Delivery Charge!"
      else
        flash[:error] = @charge.errors.full_messages.first.to_s
      end
    end

    redirect_to request.referer
  end

  def update_charge
    @charge = DistanceDeliveryCharge.find_by(id: params[:delivery_charge_id])
    new_range = params[:min_distance].to_f...params[:max_distance].to_f
    @overlap = DistanceDeliveryCharge.overlapping_range(new_range, @charge.id, params[:country_id])

    if @admin.class.name == "SuperAdmin"
      if @overlap
        flash[:error] = "Range already present"
      elsif @charge&.update(min_distance: params[:min_distance], max_distance: params[:max_distance], charge: params[:charge], min_order_amount: params[:min_order_amount], delivery_service: params[:delivery_service], country_id: params[:country_id])
        flash[:success] = "Successfully Updated Delivery Charge!"
      else
        flash[:error] = "Update Not Successful"
      end
    else
      country_id = @admin.class.find(@admin.id)[:country_id]

      if @overlap
        flash[:error] = "Range already present"
      elsif @charge&.update(min_distance: params[:min_distance], max_distance: params[:max_distance], charge: params[:charge], min_order_amount: params[:min_order_amount], delivery_service: params[:delivery_service])
        flash[:success] = "Successfully Updated Delivery Charge!"
      else
        flash[:error] = "Update Not Successful"
      end
    end

    redirect_to request.referer
  end

  def new_fixed_charge
    @delivery_charge = DeliveryCharge.new
    @delivery_charge.delivery_percentage = params[:delivery_percentage]

    if @admin.class.name == "SuperAdmin"
      @delivery_charge.country_id = params[:charge_country_id]
    else
      @delivery_charge.country_id = @admin.country_id
    end

    if @delivery_charge.save
      flash[:success] = "Delivery Charge Successfully Created!"
    else
      flash[:error] = @delivery_charge.errors.full_messages.first.to_s
    end

    redirect_to request.referer
  end

  def update_fixed_charge
    @delivery_charge = DeliveryCharge.find(params[:delivery_charge_id])
    @delivery_charge&.update(delivery_percentage: params[:delivery_percentage]) if params[:delivery_percentage].to_f >= 0
    flash[:success] = "Successfully Updated Fixed Delivery Charge!"
    redirect_to request.referer
  end

  def destroy
    @charge = DistanceDeliveryCharge.find(params[:id])
    @charge.destroy
    flash[:success] = "Deleted Successfully"
    redirect_to request.referer
  end

  private

  def delivery_charge_params
    params.require(:distance_delivery_charge).permit(:min_distance, :max_distance, :charge, :min_order_amount, :delivery_service)
  end
end
