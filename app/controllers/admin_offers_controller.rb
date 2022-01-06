class AdminOffersController < ApplicationController
  before_action :require_admin_logged_in

  def index
    if @admin.class.name == "SuperAdmin"
      @offers = AdminOffer.all
      @countries = Country.where(id: @offers.pluck(:country_id)).pluck(:name, :id)
    else
      @offers = AdminOffer.where(country_id: @admin.country_id)
    end

    @offers = @offers.search_by_title(params[:keyword]) if params[:keyword].present?
    @offers = @offers.search_by_country(params[:searched_country_id]) if params[:searched_country_id].present?
    @offers = @offers.order(created_at: :desc)

    respond_to do |format|
      format.html do
        @offers = @offers.paginate(page: params[:page], per_page: 20)
        render layout: "admin_application"
      end

      format.csv { send_data @offers.admin_offer_list_csv, filename: "Admin Offer List.csv" }
    end
  end

  def new
    @offer = AdminOffer.new
    render layout: "admin_application"
  end

  def create
    @offer = AdminOffer.new(admin_offer_params)

    if @offer.save
      image_url = params[:admin_offer][:offer_image].present? ? upload_multipart_image(params[:admin_offer][:offer_image], "admin") : nil
      @offer.update(offer_image: image_url)
      flash[:success] = "Created Successfully!"
    else
      flash[:error] = @offer.errors.full_messages.first.to_s
    end

    redirect_to admin_offers_path
  end

  def edit
    @offer = AdminOffer.find(params[:id])
    render layout: "admin_application"
  end

  def update
    @offer = AdminOffer.find(params[:id])

    if @offer.update(admin_offer_params)
      prev_img = @offer.offer_image.present? ? @offer.offer_image.split("/").last : "n/a"
      image_url = params[:admin_offer][:offer_image].present? ? update_multipart_image(prev_img, params[:admin_offer][:offer_image], "admin") : @offer.offer_image
      @offer.update(offer_image: image_url)
      flash[:success] = "Uptated Successfully!"
    else
      flash[:error] = @offer.errors.full_messages.first.to_s
    end

    redirect_to admin_offers_path
  end

  def show
    @offer = AdminOffer.find(params[:id])
    @business_offers = @offer.offers
    @business_offers = @business_offers.where("DATE(offers.start_date) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @business_offers = @business_offers.where("DATE(offers.start_date) <= ?", params[:end_date].to_date) if params[:end_date].present?

    respond_to do |format|
      format.html do
        @business_offers = @business_offers.paginate(page: params[:page], per_page: 30)
        render layout: "admin_application"
      end

      format.csv { send_data @business_offers.business_offer_list_csv(@offer), filename: "business_offer_list.csv" }
    end
  end

  def destroy
    @offer = AdminOffer.find(params[:id])

    if @offer&.destroy
      flash[:success] = "Deleted Successfully!"
    else
      flash[:error] = "Cannot Delete"
    end

    redirect_to admin_offers_path
  end

  private

  def admin_offer_params
    params.require(:admin_offer).permit(:offer_title, :offer_percentage, :offer_image, :country_id, :limit)
  end
end
