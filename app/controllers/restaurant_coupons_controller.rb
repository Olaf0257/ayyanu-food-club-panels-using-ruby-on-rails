class RestaurantCouponsController < ApplicationController
  before_action :require_admin_logged_in, :find_enabled_restaurants
  layout "admin_application"

  def index
    if @admin.class.name == "SuperAdmin"
      @coupons = RestaurantCoupon.all
    else
      @coupons = RestaurantCoupon.where(country_id: @admin.country_id)
    end

    @countries = @coupons.joins(:country).pluck("countries.name, countries.id").uniq.sort
    @coupons = @coupons.filter_by_keyword(params[:searched_country_id], params[:keyword], params[:start_date], params[:end_date])
    @coupons = @coupons.distinct.order_by_date

    respond_to do |format|
      format.html { @coupons = @coupons.paginate(page: params[:page], per_page: 50) }
      format.csv { send_data @coupons.restaurant_coupon_list_csv(params[:searched_country_id], params[:start_date], params[:end_date]), filename: "restaurant_coupon_list.csv" }
    end
  end

  def new
    @coupon = RestaurantCoupon.new
  end

  def create
    @coupon = RestaurantCoupon.new(restaurant_coupon_params)
    existing_offers = Offer.where(branch_id: params.select { |k, _v| k.include?("branch_ids") }.values.flatten.uniq).select { |o| (o.start_date.to_date..o.end_date.to_date).overlaps?(restaurant_coupon_params[:start_date].to_date..restaurant_coupon_params[:end_date].to_date) }

    if existing_offers.present?
      flash[:error] = "Sweet Deals already present for this date range"
      render "new"
    else
      @coupon.quantity = @coupon.total_quantity
      @coupon.country_id = params[:country_id]

      if @coupon.save
        update_restaurant_coupon_restaurants(@coupon)
        RestaurantCouponWorker.perform_async(@coupon.id, @admin.class.name == "SuperAdmin")
        flash[:success] = "Coupon Successfully Created!"
        redirect_to restaurant_coupons_path
      else
        flash[:error] = @coupon.errors.full_messages.first.to_s
        render "new"
      end
    end
  end

  def edit
    @coupon = RestaurantCoupon.find(params[:id])
  end

  def update
    @coupon = RestaurantCoupon.find(params[:id])
    existing_offers = Offer.where(branch_id: params.select { |k, _v| k.include?("branch_ids") }.values.flatten.uniq).select { |o| (o.start_date.to_date..o.end_date.to_date).overlaps?(restaurant_coupon_params[:start_date].to_date..restaurant_coupon_params[:end_date].to_date) }

    if existing_offers.present?
      flash[:error] = "Sweet Deals already present for this date range"
      render "edit"
    else
      old_qty = @coupon.total_quantity

      if @coupon.update(restaurant_coupon_params)
        new_qty = @coupon.total_quantity
        qty_diff = new_qty - old_qty
        @coupon.update(quantity: (@coupon.quantity + qty_diff))
        update_restaurant_coupon_restaurants(@coupon)
        RestaurantCouponWorker.perform_async(@coupon.id, (@admin.class.name == "SuperAdmin" ? nil : @admin.country_id))
        flash[:success] = "Coupon Successfully Updated!"
        redirect_to restaurant_coupons_path
      else
        flash[:error] = @coupon.errors.full_messages.first.to_s
        render "edit"
      end
    end
  end

  def show
    @coupon = RestaurantCoupon.find(params[:id])
    @branches = @coupon.branches.group_by(&:restaurant_id)
  end

  def activate
    @coupon = RestaurantCoupon.find(params[:id])
    @coupon.update(active: params[:active].present?)
    flash[:success] = "Coupon #{params[:active].present? ? 'Activated' : 'Deactivated'} Successfully!"
    redirect_to restaurant_coupons_path
  end

  def user_list
    @coupon = RestaurantCoupon.find(params[:id])
    @restaurant_coupon_users = @coupon.restaurant_coupon_users
    @restaurant_coupon_users = @restaurant_coupon_users.where("DATE(created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @restaurant_coupon_users = @restaurant_coupon_users.where("DATE(created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @restaurant_coupon_users = @restaurant_coupon_users.order(id: :desc)

    respond_to do |format|
      format.js {}
      format.csv { send_data @restaurant_coupon_users.list_csv(@coupon.coupon_code), filename: "restaurant_coupon_users_list_.csv" }
    end
  end

  def view_notes
    @coupon = RestaurantCoupon.find(params[:id])
  end

  def destroy
    @coupon = RestaurantCoupon.find(params[:id])
    @coupon.destroy
    flash[:success] = "Coupon Deleted Successfully!"
    redirect_to restaurant_coupons_path
  end

  private

  def find_enabled_restaurants
    @restaurants = if @admin.class.name == "User"
                     Restaurant.joins(:branches).where(is_signed: true, country_id: @admin.country_id, branches: { is_approved: true }).where.not(title: "").distinct.pluck(:title, :id).sort
                   else
                     Restaurant.joins(:branches).where(is_signed: true, country_id: params[:country_id], branches: { is_approved: true }).where.not(title: "").distinct.pluck(:title, :id).sort
                   end
  end

  def restaurant_coupon_params
    params.require(:restaurant_coupon).permit(:coupon_code, :discount, :discount, :total_quantity, :start_date, :end_date, :notes)
  end
end
