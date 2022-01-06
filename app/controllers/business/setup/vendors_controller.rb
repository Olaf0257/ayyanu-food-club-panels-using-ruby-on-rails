class Business::Setup::VendorsController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @vendors = @restaurant.vendors.all.order("created_at DESC")
    @countries = Country.where(id: @vendors.pluck(:country_id).uniq).pluck(:name, :id).sort
    @areas = get_coverage_area_web("", 1, 300).where(id: @vendors.pluck(:area_id).uniq).pluck(:area, :id).sort
    @vendors = @vendors.where(country_id: params[:country_id]) if params[:country_id].present?
    @vendors = @areas.where(arae_id: params[:arae_id]) if params[:arae_id].present?
    @vendors = @vendors.where("company_name LIKE ? OR company_registration_no LIKE ? OR mobile_no LIKE ?", "%#{params[:keyword]}%","%#{params[:keyword]}%","%#{params[:keyword]}%") if params[:keyword].present?
    render :layout => 'partner_application'
  end

  def new
    @vendor = Vendor.new
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
  end

  def create
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    @vendor_user = User.create(user_params)
    @vendor = Vendor.new(vendor_params)
    @vendor.restaurant_id = @restaurant.id
    @vendor.user_id = @vendor_user.id
    if @vendor_user.id.present? && @vendor.save
      flash[:success] = "Created Successfully!"
      redirect_to business_setup_vendors_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @vendor_user.errors.full_messages.join(", ") || @vendor.errors.full_messages.join(", ") 
      render :new
    end
  end

  def edit
    @vendor = Vendor.find_by(id: params[:id])
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @areas = get_coverage_area_web("", 1, 300).where(country_id: @restaurant.country_id)
    render layout: "partner_application"
  end

  def update
    @vendor = Vendor.find_by(id: params[:id])
    @vendor.user.update(user_params)
    if @vendor.update(vendor_params)
      flash[:success] = "Updated Successfully!"
      redirect_to business_setup_vendors_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @vendor.errors.full_messages.join(", ")
    end
  end

  def destroy
    @vendor = Vendor.find_by(id: params[:id])
    if @vendor.destroy
      flash[:success] = "Deleted Successfully!"
      redirect_to business_setup_vendors_path(restaurant_id: params[:restaurant_id])
    else
      flash[:error] = @vendor.errors.full_messages.join(", ")
    end
  end


  def change_vendors_state
    @vendor =Vendor.find_by_id(params[:vendor_id])
    status =ActiveModel::Type::Boolean.new.cast(params["status"])
    @vendor.update(status: status)
    flash[:message] = "Vendor status updated."
     respond_to do |format|
      format.js { }
    end
  end

  private
  def user_params
    params.require(:user).permit(:first_name,
                                 :email,
                                 :last_name,
                                 :middle_name
                                )
  end

  def vendor_params
    params.require(:vendor).permit(:company_name,
                                      :company_registration_no,
                                      :mobile_no,
                                      :phone_no,
                                      :area_id,
                                      :city,
                                      :country_id,
                                      :user_id,
                                      :status,
                                      :address,
                                      :company_registration_expiry_date,
                                      :tax_percentage,
                                      :name_of_company_representative,
                                      :mobile_code,
                                      :landline_code
                                    )
  end
end
