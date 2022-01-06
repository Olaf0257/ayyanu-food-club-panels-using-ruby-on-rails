class Customer::RestaurantsController < ApplicationController
  before_action :authenticate_customer

  def list
    if params[:latitude].present? && params[:longitude].present?
      location = params[:location].presence || params[:address]
      area_ids = get_coverage_area_from_location(params[:latitude].to_f, params[:longitude].to_f)
      all_areas = CoverageArea.where(id: area_ids)
      selected_area_id = all_areas.select { |a| location.to_s.squish.downcase.include?(a.area.downcase) }.first&.id
      @area = CoverageArea.find_by(id: (selected_area_id.presence || area_ids.first))
    end

    @area ||= CoverageArea.find_by(area: params[:search])
    @cuisine_id = decode_token(params[:cuisine_id]) if params[:cuisine_id].present?
    @restaurant_id = decode_token(params[:restaurant_id]) if params[:restaurant_id].present?

    if params[:search].blank? && params[:latitude].blank? && params[:longitude].blank?
      @country_id = session[:country_id]
      @all_areas = CoverageArea.active_areas.where(country_id: @country_id)
      @branches = []
      @cuisines = []
    else
      if @area.present?
        @area_id = @area.id
      else
        flash[:error] = "Area not found"
        redirect_to request.referer
        return
      end

      @branches = Branch.find_area_wise_branch(@area_id)
      @branches = Branch.where(id: @branches.map(&:id).uniq).joins(:restaurant, :branch_coverage_areas).distinct
      @branches = @branches.joins(:branch_categories).where(branch_categories: { category_id: @cuisine_id }).distinct if @cuisine_id
      @cuisines = Category.joins(:branch_categories).where(branch_categories: { branch_id: @branches.pluck(:id) }).distinct.order("categories.title")
      @branches = @branches.where(restaurants: { id: @restaurant_id }).distinct if @restaurant_id.present?
      @branches = @branches.web_filter_by_criteria(params[:filter], @area_id).distinct if params[:filter].present?
      @all_branches = @branches
      @branches = @branches.where("restaurants.title like ?", "%#{params[:keyword].squish}%").distinct if params[:keyword].present?
      @branches = @branches.order_branches

      if params[:keyword].to_s.squish.length > 1
        @menu_items = search_menu_item(@all_branches.pluck(:id), @area, params[:keyword].squish, 1, 100)
        @polling_branches = search_polling_branches(@area, params[:keyword].squish, 1, 100)
        @branch_without_area = search_branches_without_area(@area, params[:keyword].squish, 1, 100)
        @branches += (@polling_branches + @branch_without_area).sort_by { |b| b.restaurant.title }
        @branches = @branches.uniq(&:restaurant_id)
      end

      @branches.each do |b|
        b.area = @area_id
      end

      @branches = @branches.sort_by { |b| !b.is_closed && !b.is_busy ? 0 : 1 }

      if @branches.empty? && @all_areas.blank? && params[:keyword].to_s.squish.blank? && params[:filter].to_s.blank?
        if params[:cuisine_id].present?
          flash[:warning] = "No Restaurant Open for this Cuisine in this Area now"
          redirect_to request.referer
        elsif params[:restaurant_id].present?
          flash[:warning] = "This Restaurant is not Open in this Area now"
          redirect_to request.referer
        end
      end
    end
  end

  def restaurant_details
    @user = current_user
    @branch = Branch.find(decode_token(params[:id]))
    @area = CoverageArea.find(decode_token(params[:area_id]))
    @reviews = @branch.ratings.order(id: :desc).limit(10)
    most_selling = Branch.get_most_selling_data(@branch, @user, nil, nil, nil, @area.id)
    @menu = get_branch_menu_list(@user, @guestToken, @branch, nil, nil, most_selling.present? ? most_selling["items"].pluck("id") : [], @area.id, params[:keyword])
    @menu = @menu.insert(0, most_selling) if most_selling.present? && params[:keyword].to_s.squish.blank?
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    @cart_data = cart_list_json(get_cart_item_list(cart, request.headers["language"])) if cart
  end

  def offer_list
    @offers = Offer.active.running.joins(branch: :restaurant).where(restaurants: { country_id: session[:country_id], is_signed: true }, branches: { is_approved: true }).distinct
  end

  def submit_branch_rating
    branch_id = params[:branch_id]
    user_id = params[:user_id]
    review = params[:review]
    @rating = Rating.new(review_description: review, branch_id: branch_id, user_id: user_id)
  end
end
