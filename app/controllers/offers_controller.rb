class OffersController < ApplicationController
  before_action :require_admin_logged_in

  def offers_list
    render layout: "admin_application"
  end

  def offers_list_show
    @offers = find_place_offers(params[:position]).where(place: (params[:ad_type].presence || "list"))
    @offers = @offers.where("DATE(add_requests.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @offers = @offers.where("DATE(add_requests.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @offers = @offers.joins(branch: :restaurant).where("restaurants.title like ? OR branches.address like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    @offers = @offers.where(is_accepted: true) if params[:status].to_s == "Approved"
    @offers = @offers.where(is_reject: true) if params[:status].to_s == "Rejected"
    @offers = @offers.where(is_accepted: false, is_reject: nil) if params[:status].to_s == "Pending"
    @offers = @offers.distinct.order(id: :desc)

    respond_to do |format|
      format.html do
        @offers = @offers.paginate(per_page: params[:per_page], page: params[:page])
        render layout: "admin_application"
      end

      format.csv { send_data @offers.offers_list_csv, filename: "offers_list.csv" }
    end
  end

  def offer_show
    @offer = find_adds_req(decode_token(params[:offer_id]))
    render layout: "admin_application"
  end

  def new_week_list
    render layout: "admin_application"
  end

  def accept_add_request
    if params[:reject].present?
      AddRequest.find_by(id: params[:add_id])&.update(is_reject: true)
      send_json_response("Request Rejected", "success", {})
    else
      add_req = add_request_action(params[:add_id])
      if add_req[:status]
        admin = SuperAdmin.last
        offerPushNotificationWorker(admin, add_req[:req].restaurant.user, "offer_accepted", "Offer Accepted", "Offer is accepted by admin", add_req[:req].id)
        send_json_response("Request Accepted", "success", {})
      else
        send_json_response("Invalid Request", "invalid", {})
      end
    end
  end

  def week_list
    if @admin.class.name =='SuperAdmin'
      @weeks = Week.all.order("id DESC").paginate(per_page: params[:per_page], page: params[:page])
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @weeks = Week.all.where(country_id: country_id).order("id DESC").paginate(per_page: params[:per_page], page: params[:page])
    end
    render layout: "admin_application"
  end

  def admin_advertisement_list
    @advertisements = get_all_advertisement_list(params[:ad_type], params[:keyword], params[:status], params[:start_date], params[:end_date])

    respond_to do |format|
      format.html do
        @advertisements = @advertisements.paginate(per_page: params[:per_page], page: params[:page])
        render layout: "admin_application"
      end

      format.csv { send_data @advertisements.admin_advertisement_list_csv, filename: "advertisement_list.csv" }
    end
  end

  def rejected_advertisement_list
    @reject_list = rejected_add_list(params[:ad_type])
    @reject_list = @reject_list.where("DATE(add_requests.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @reject_list = @reject_list.where("DATE(add_requests.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @reject_list = @reject_list.joins(branch: :restaurant).where("restaurants.title like ? OR branches.address like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    @reject_list = @reject_list.distinct.order(id: :desc)

    respond_to do |format|
      format.html do
        @reject_list = @reject_list.paginate(per_page: params[:per_page], page: params[:page])
        render layout: "admin_application"
      end

      format.csv { send_data @reject_list.rejected_advertisement_list_csv, filename: "rejected_advertisement_list.csv" }
    end
  end

  def branch_offer_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    branches = @restaurant.branches
    @offers = get_restaurant_offers(branches)
    @offers = @offers.paginate(page: params[:page], per_page: params[:per_page])
    render layout: "admin_application"
  end

  def add_branch_offer
    @restaurant = get_restaurant_data(decode_token(params[:id]))
    @branches = @restaurant.branches
    @menu = get_branch_menu(@branches.first)
    render layout: "admin_application"
  end

  def branch_new_menu_offer
    @branch = get_branch_data(params[:branch])
    if @branch
      if params[:menu_item].present?
        offer = add_branch_menu_offer(@branch, params[:offer_title], params[:start_date], params[:end_date], params[:menu_item], params[:discount_percentage], params[:offer_image], params[:offer_type])
        flash[:success] = "Menu Item added sucessfully"
      else
        flash[:error] = "Invalid"
      end
    else
      flash[:error] = "Invalid"
    end
    redirect_to branch_offer_list_path(restaurant_id: encode_token(@branch.restaurant.id))
  end

  def remove_week
    week = Week.find_by(id: params[:week_id])
    if week.present?
      week.destroy
      send_json_response("week remove", "success", {})
    else
      send_json_response("week", "not exist", {})
    end
  end
end
