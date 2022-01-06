class Business::OffersController < ApplicationController
  before_action :authenticate_business, except: [:change_offer_status]

  def advertisement_list
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant
      @restaurant = restaurant
      data = get_restaurant_advertisement(@restaurant, params[:ad_type])
      @advertisements = data.includes(:restaurant, :branch)

      respond_to do |format|
        format.html do
          @advertisements = @advertisements.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @advertisements.business_advertisement_list_csv, filename: "advertisement_list.csv" }
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def add_advertisement
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @branches = restaurant.branches
      @weekes = week_data(restaurant.country_id)
      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end
  end

  def add_new_advertisement
    # restaurant = params[:rest_id]
    restaurant = params[:rest_id]
    if params[:weeks].present?
      add = new_adds_request(params[:space], params[:advertisement_type], params[:title], params[:description], params[:amount], params[:weeks], params[:branch], params[:region], params[:branch_image])

      if add
        @webPusher = web_pusher(Rails.env)
        pusher_client = Pusher::Client.new(
          app_id: @webPusher[:app_id],
          key: @webPusher[:key],
          secret: @webPusher[:secret],
          cluster: "ap2",
          encrypted: true
        )
        pusher_client.trigger("my-channel", "my-event",
                              message: "hello world")

        CreateAddRequestWorker.perform_async(add.id) if add.place == "list"
        redirect_to business_pending_advertisement_list_path(restaurant_id: restaurant)
      else
        flash[:error] = "Invalid Add !!"
        redirect_to business_pending_advertisement_list_path(restaurant_id: restaurant)
      end
    else
      flash[:error] = "Week not present!!"
      redirect_to business_pending_advertisement_list_path(restaurant_id: restaurant)
    end
  end

  def offer_list
    if params[:restaurant_id].present?
      restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
      @branches = restaurant.branches
    else
      restaurant = Branch.where(id: @user.manager_branches.pluck(:branch_id)).first&.restaurant
      @branches = Branch.where(id: @user.manager_branches.pluck(:branch_id))
    end

    if restaurant
      data = get_restaurant_offers(@branches)
      data = data.where(branch_id: params[:searched_branch]) if params[:searched_branch].present?
      @offers = data.includes(:menu_item, :branch)

      respond_to do |format|
        format.html do
          @offers = @offers.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @offers.sweet_deal_offer_list_csv, filename: "Sweet Deal Offer List.csv" }
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def admin_offer_percentage
    @offer_id = params[:offer_id]
    @percentage = AdminOffer.find(@offer_id).offer_percentage.to_s
    render json: { discount: @percentage }
  end

  def add_offer
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @available_admin_offers = AdminOffer.where(country_id: restaurant.country_id).pluck(:offer_title, :id)
      @branches = restaurant.branches
      @menu = get_branch_menu(@branches.first)
      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end
  end

  def new_menu_offer
    restaurant = params[:rest_id]
    @branch = get_branch_data(params[:branch])

    if @branch
      existing_influencer_coupons = InfluencerCoupon.joins(:influencer_coupon_branches).where(influencer_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }
      existing_referral_coupons = ReferralCoupon.joins(:referral_coupon_branches).where(referral_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }
      existing_restaurant_coupons = RestaurantCoupon.joins(:restaurant_coupon_branches).where(restaurant_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }

      if existing_influencer_coupons.present? || existing_referral_coupons.present? || existing_restaurant_coupons.present?
        flash[:error] = "Coupons already present for this date range"
      else
        offer = Offer.create(branch_id: @branch.id, include_in_pos: params[:include_in_pos],include_in_app: params[:include_in_app],admin_offer_id: params[:admin_offer_id], offer_type: params[:offer_type], discount_percentage: params[:discount_percentage], start_date: params[:start_date].to_datetime, end_date: params[:end_date].to_datetime, menu_item_id: (params[:offer_type] == "individual" ? params[:menu_item] : ""), start_time: params[:start_date] + " " + params[:start_time], end_time: params[:end_date] + " " + params[:end_time], limited_quantity: params[:limited_quantity].present?, quantity: (params[:limited_quantity].present? ? params[:quantity] : nil), limit: params[:limit])

        begin
          send_notification_releted_menu("#{@branch.restaurant.title} Restaurant has added a new sweet deal", "offer_created", @branch.restaurant.user, get_admin_user, @branch.restaurant_id)
          RestaurantMailer.send_offer_email_restaurant(@branch.restaurant, offer).deliver_now
        rescue Exception => e
        end

        flash[:success] = "Menu Item offer added sucessfully"
      end
    else
      flash[:error] = "Invalid"
    end

    redirect_to business_offer_list_path(restaurant_id: restaurant)
  end

  def update_offer
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if restaurant
      @available_admin_offers = AdminOffer.where(country_id: restaurant.country_id).pluck(:offer_title, :id)
      @branches = restaurant.branches
      @offer = get_menu_offer(decode_token(params[:offer_id]))
      @menu = get_branch_menu(@offer.branch)
      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end
  end

  def edit_offer
    restaurant = params[:rest_id]
    @offer = get_menu_offer(params[:offer_id])
    @branch = get_branch_data(params[:branch])

    if @offer
      existing_influencer_coupons = InfluencerCoupon.joins(:influencer_coupon_branches).where(influencer_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }
      existing_referral_coupons = ReferralCoupon.joins(:referral_coupon_branches).where(referral_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }
      existing_restaurant_coupons = RestaurantCoupon.joins(:restaurant_coupon_branches).where(restaurant_coupon_branches: { branch_id: @branch.id }).select { |c| (c.start_date..c.end_date).overlaps?(params[:start_date].to_date..params[:end_date].to_date) }

      if existing_influencer_coupons.present? || existing_referral_coupons.present? || existing_restaurant_coupons.present?
        flash[:error] = "Coupons already present for this date range"
      else
        offer = @offer.update(
          branch_id: @branch.id, include_in_pos: params[:include_in_pos],
          include_in_app: params[:include_in_app], admin_offer_id: params[:admin_offer_id],
          offer_type: params[:offer_type], discount_percentage: params[:discount_percentage],
          start_date: params[:start_date].to_datetime, end_date: params[:end_date].to_datetime,
          menu_item_id: (params[:offer_type] == "individual" ? params[:menu_item] : ""),
          start_time: params[:start_date] + " " + params[:start_time],
          end_time: params[:end_date] + " " + params[:end_time],
          limited_quantity: params[:limited_quantity].present?,
          quantity: (params[:limited_quantity].present? ? params[:quantity] : nil),
          is_active: true, limit: params[:limit])

        begin
          RestaurantMailer.send_offer_email_restaurant(@branch.restaurant, @offer).deliver_now
        rescue Exception => e
        end

        flash[:success] = "Menu Item offer update sucessfully"
      end
    else
      flash[:error] = "Invalid"
    end
    redirect_to business_offer_list_path(restaurant_id: restaurant)
  end

  def remove_offer
    @offer = get_menu_offer(params[:offer_id])
    if @offer.present?
      remove_multipart_image(@offer.offer_image.split("/").last, "advertisement") if @offer.offer_image.present?
      PosCheck.where(offer_id: @offer.id).update_all(offer_id: nil)
      @offer.destroy
      send_json_response("Offer remove", "success", {})
    else
      send_json_response("Offer", "not exist", {})
    end
  end

  def pending_advertisement_list
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @ads = get_pending_ads_data(@user, @restaurant, params[:ad_type])

      respond_to do |format|
        format.html do
          @ads = @ads.paginate(page: params[:page], per_page: params[:per_page])
          render layout: "partner_application"
        end

        format.csv { send_data @ads.pending_advertisement_list_csv, filename: "Pending_advertisement_list.csv" }
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def offer_show
    @offer = find_adds_req(decode_token(params[:offer_id]))
    render layout: "partner_application"
  end

  def update_pending_offer
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @offer = find_adds_req(decode_token(params[:offer_id]))
    @weekes = Week.all
    @branches = @restaurant.branches
    render layout: "partner_application"
  end

  def edit_pending_offer
    @offer = find_adds_req(params[:offer_id])
    if @offer
      offer = update_pending_offer_record(@offer, params[:space], params[:advertisement_type], params[:title], params[:description], params[:amount], params[:weeks], params[:branch], params[:region], params[:branch_image])
      flash[:success] = "Update sucessfully"
    else
      flash[:error] = "Invalid Ads!!"
    end
    redirect_to business_pending_advertisement_list_path(restaurant_id: encode_token(@offer.branch.restaurant_id))
  end

  def change_offer_status
    @offer = get_menu_offer(params[:offer_id])

    if @offer.present?
      if @offer.end_date.to_date >= Date.today
        @offer.update(is_active: @offer.is_active ? false : true)
        send_json_response("Offer status changed", "success", {})
      else
        send_json_response("Offer already expired", "success", {})
      end
    else
      send_json_response("Offer", "not exist", {})
    end
  end
end
