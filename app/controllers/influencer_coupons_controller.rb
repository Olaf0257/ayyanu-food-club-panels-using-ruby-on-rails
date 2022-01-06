class InfluencerCouponsController < ApplicationController
  before_action :require_admin_logged_in, :find_influencers, :find_enabled_restaurants
  layout "admin_application"

  def index
    @coupons = if @admin.class.name == "User"
                 InfluencerCoupon.includes(user: :country).where(users: { country_id: @admin.country_id })
               else
                 InfluencerCoupon.includes(user: :country)
               end

    @countries = @coupons.joins(user: :country).pluck("countries.name, countries.id").uniq.sort
    @coupons = @coupons.filter_by_keyword(params[:searched_country_id], params[:keyword], params[:start_date], params[:end_date])
    @coupons = @coupons.distinct.order_by_date

    respond_to do |format|
      format.html { @coupons = @coupons.paginate(page: params[:page], per_page: 50) }
      format.csv { send_data @coupons.influencer_coupon_list_csv(params[:searched_country_id], params[:start_date], params[:end_date]), filename: "influencer_coupon_list.csv" }
    end
  end

  def new
    @coupon = InfluencerCoupon.new
  end

  def create
    @coupon = InfluencerCoupon.new(influencer_coupon_params)
    existing_offers = Offer.where(branch_id: params.select { |k, _v| k.include?("branch_ids") }.values.flatten.uniq).select { |o| (o.start_date.to_date..o.end_date.to_date).overlaps?(influencer_coupon_params[:start_date].to_date..influencer_coupon_params[:end_date].to_date) }

    if existing_offers.present?
      flash[:error] = "Sweet Deals already present for this date range"
      render "new"
    else
      @coupon.quantity = @coupon.total_quantity
      @coupon.country_id = params[:country_id]

      if @coupon.save
        update_influencer_coupon_restaurants(@coupon)
        InfluencerCouponWorker.perform_async(@coupon.id)
        flash[:success] = "Coupon Successfully Created!"
        redirect_to influencer_coupons_path
      else
        flash[:error] = @coupon.errors.full_messages.first.to_s
        render "new"
      end
    end
  end

  def edit
    @coupon = InfluencerCoupon.find(params[:id])
  end

  def update
    @coupon = InfluencerCoupon.find(params[:id])
    existing_offers = Offer.where(branch_id: params.select { |k, _v| k.include?("branch_ids") }.values.flatten.uniq).select { |o| (o.start_date.to_date..o.end_date.to_date).overlaps?(influencer_coupon_params[:start_date].to_date..influencer_coupon_params[:end_date].to_date) }

    if existing_offers.present?
      flash[:error] = "Sweet Deals already present for this date range"
      render "edit"
    else
      old_qty = @coupon.total_quantity

      if @coupon.update(influencer_coupon_params)
        new_qty = @coupon.total_quantity
        qty_diff = new_qty - old_qty
        @coupon.update(quantity: (@coupon.quantity + qty_diff))
        update_influencer_coupon_restaurants(@coupon)
        InfluencerCouponWorker.perform_async(@coupon.id)
        flash[:success] = "Coupon Successfully Updated!"
        redirect_to influencer_coupons_path
      else
        flash[:error] = @coupon.errors.full_messages.first.to_s
        render "edit"
      end
    end
  end

  def activate
    @coupon = InfluencerCoupon.find(params[:id])
    @coupon.update(active: params[:active].present?)
    flash[:success] = "Coupon #{params[:active].present? ? 'Activated' : 'Deactivated'} Successfully!"
    redirect_to influencer_coupons_path
  end

  def branch_list
    @restaurant = Restaurant.find(params[:restaurant_id])
    @branches = @restaurant.branches.where(is_approved: true).pluck(:address, :id).sort
    @count = params[:row_id].to_i
  end

  def category_list
    if params[:branch_ids].present?
      @branches = Branch.where(id: params[:branch_ids].to_s.split(","))
    else
      @branches = Branch.where(restaurant_id: params[:restaurant_id], is_approved: true)
    end

    @categories = MenuCategory.where(branch_id: @branches.pluck(:id)).pluck(:category_title, :id).sort
    @count = params[:row_id].to_i
  end

  def item_list
    if params[:category_ids].present?
      @categories = MenuCategory.where(id: params[:category_ids].to_s.split(","))
    else
      @categories = MenuCategory.joins(:branch).where(branches: { restaurant_id: params[:restaurant_id], is_approved: true })
    end

    @items = MenuItem.where(menu_category_id: @categories.pluck(:id)).pluck(:item_name, :id).sort
    @count = params[:row_id].to_i
  end

  def add_new_row
    @count = params[:row_id].to_i + 1
  end

  def show
    @coupon = InfluencerCoupon.find(params[:id])
    @branches = @coupon.branches.group_by(&:restaurant_id)
  end

  def user_list
    @coupon = InfluencerCoupon.find(params[:id])
    @influencer_coupon_users = @coupon.influencer_coupon_users
    @influencer_coupon_users = @influencer_coupon_users.where("DATE(created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @influencer_coupon_users = @influencer_coupon_users.where("DATE(created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @influencer_coupon_users = @influencer_coupon_users.order(id: :desc)

    respond_to do |format|
      format.js {}
      format.csv { send_data @influencer_coupon_users.list_csv(@coupon.coupon_code), filename: "influencer_coupon_users_list_.csv" }
    end
  end

  def view_notes
    @coupon = InfluencerCoupon.find(params[:id])
  end

  def destroy
    @coupon = InfluencerCoupon.find(params[:id])
    @coupon.destroy
    flash[:success] = "Coupon Deleted Successfully!"
    redirect_to influencer_coupons_path
  end

  private

  def find_influencers
    @influencers = if @admin.class.name == "User"
                     User.influencer_users.where(is_approved: 1, country_id: @admin.country_id).pluck(:name, :id).sort
                   else
                     User.influencer_users.where(is_approved: 1, country_id: params[:country_id]).pluck(:name, :id).sort
                   end
  end

  def find_enabled_restaurants
    @restaurants = if @admin.class.name == "User"
                     Restaurant.joins(:branches).where(is_signed: true, country_id: @admin.country_id, branches: { is_approved: true }).where.not(title: "").distinct.pluck(:title, :id).sort
                   else
                     Restaurant.joins(:branches).where(is_signed: true, country_id: params[:country_id], branches: { is_approved: true }).where.not(title: "").distinct.pluck(:title, :id).sort
                   end
  end

  def influencer_coupon_params
    params.require(:influencer_coupon).permit(:user_id, :coupon_code, :discount, :total_quantity, :start_date, :end_date, :notes)
  end
end
