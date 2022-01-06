class ReportsController < ApplicationController
  before_action :require_admin_logged_in

  def area_orders_report
    @restaurant = get_restaurant(params[:id])
    if @restaurant
      @branches = @restaurant.branches
      @areas = get_branches_coverage_area(@branches)
      @area_wise = get_area_wise_report(@branches, params[:area], params[:branch], params[:start_date], params[:end_date])
    end
    render layout: "admin_application"
  end

  def day_orders
    @orders = if params[:key] == "morning"
                Order.where("created_at>=? and created_at <= ?", Time.parse("8am"), Time.parse("12pm"))
              elsif params[:key] == "lunch"
                Order.where("created_at>=? and created_at <= ?", Time.parse("12pm"), Time.parse("6pm"))
              elsif params[:key] == "dinner"
                Order.where("created_at>=? and created_at <= ?", Time.parse("6pm"), Time.parse("10pm"))
              else
                Order.where("created_at>=? and created_at <= ?", Time.parse("8am"), Time.parse("10pm"))
               end
    # @morning_orders =Order.where("created_at>=? and created_at <= ?",Time.parse('8am'),Time.parse('12pm'))
    # @lunch_orders =Order.where("created_at>=? and created_at <= ?",Time.parse('12pm'),Time.parse('6pm'))
    # @dinner_orders =Order.where("created_at>=? and created_at <= ?",Time.parse('6pm'),Time.parse('10pm'))
    render layout: "admin_application"
  end

  def monthly_selling_items
    render layout: "admin_application"
  end

  def top_selling_item_report
    @restaurant = get_restaurant(params[:id])
    @branches = @restaurant.branches
    @items = get_top_selling_items(params[:branch], @branches)
    render layout: "admin_application"
  end

  def admin_top_selling_item
    @restaurant = get_restaurant(params[:restaurant_id])
    if @restaurant
      @branches = @restaurant.branches
      @items = get_top_selling_items(params[:branch], @branches)
      respond_to do |format|
        format.html
        format.csv do
          headers["Content-Disposition"] = "attachment; filename=\"Top-Selling-Items-list.csv\""
          headers["Content-Type"] ||= "text/csv"
        end
        format.xlsx { render xlsx: "admin_top_selling_item", filename: "Top-Selling-Items-list.xlsx" }
      end
  end
  end

  def admin_revenue_growth_lost_report
    @restaurant = get_restaurant(params[:id])
    @branches = @restaurant.branches
    @reports = get_revenue_reports(params[:branch])
    render layout: "admin_application"
  end

  def admin_new_customer_report
    @restaurant = get_restaurant(params[:id])
    @branches = @restaurant.branches
    @data = get_new_customer_data(@branches, params[:branch], params[:start_date], params[:end_date], params[:area])
    render layout: "admin_application"
  end

  def admin_cancel_order_report
    @restaurant = get_restaurant(params[:id])
    @branches = @restaurant.branches
    @reports = get_cancel_order(params[:branch], params[:report_period])
    render layout: "admin_application"
  end

  def over_all_report
    @restaurant = get_restaurant(params[:restaurant_id])
    @currentYear = Date.current.year
    if @restaurant.present?
      @branches = @restaurant.branches
      p "=====#{@restaurant.branches.count}=========="
      branch = params[:branch].present? ? get_branch(params[:branch]) : @branches.first
      serchKey = params[:search_key].presence || "month"
      @branch_orders_graph_data = get_branch_orders_graph_data(branch, serchKey)
      @branch_order_count_graph_data = get_branch_orders_count(branch, serchKey)
    else
      @branch_orders_graph_data = nil
      @branch_order_count_graph_data = nil
     end
    render layout: "admin_application"
  end

  def admin_approved_branches_report
    @branches = Branch.approved.includes(restaurant: :country).order(:city)
    @countries = Country.where(id: @branches.map(&:restaurant).flatten.map(&:country_id).uniq).pluck(:name, :id)
    @cities = CoverageArea.pluck(:area).sort

    if params[:searched_country_id].present?
      @branches = @branches.where(restaurants: { country_id: params[:searched_country_id] })
      @cities = CoverageArea.where(country_id: params[:searched_country_id]).pluck(:area).sort
    end

    @branches = @branches.where(city: params[:searched_city]) if params[:searched_city].present?
    @branches = @branches.joins(:restaurant).where("branches.address like ? or restaurants.title like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?

    respond_to do |format|
      format.html do
        @branches = @branches.paginate(page: params[:page], per_page: 100)
        render layout: "admin_application"
      end

      format.csv  { send_data @branches.approved_list_csv, filename: "approved_branches_list.csv" }
    end
  end

  def admin_free_delivery_branches_report
    @branch_coverage_areas = BranchCoverageArea.joins(:coverage_area, branch: { restaurant: :country }).includes(:coverage_area, branch: { restaurant: :country }).where("(branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.delivery_charges = ?) OR (branch_coverage_areas.third_party_delivery = ? AND branch_coverage_areas.third_party_delivery_type = ?)", false, "0", true, "Free").where(branches: { is_approved: true }, restaurants: { is_signed: true, approved: true })
    @countries = @branch_coverage_areas.pluck("countries.name, countries.id").uniq.sort
    @restaurants = @branch_coverage_areas.pluck("restaurants.title, restaurants.id").uniq.sort
    @branch_coverage_areas = @branch_coverage_areas.where(restaurants: { country_id: @admin.country_id }) if @admin.class.name != "SuperAdmin"
    @branch_coverage_areas = @branch_coverage_areas.where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @branch_coverage_areas = @branch_coverage_areas.where(restaurants: { id: params[:restaurant_id] }) if params[:restaurant_id].present?
    @branch_coverage_areas = @branch_coverage_areas.where("branches.address like ? OR coverage_areas.area like ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    @branch_coverage_areas = @branch_coverage_areas.where(third_party_delivery: (params[:delivery_type] == "true")) if params[:delivery_type].present?
    @branch_coverage_areas = @branch_coverage_areas.distinct.order("restaurants.title, branches.address, coverage_areas.area")

    respond_to do |format|
      format.html do
        @branch_coverage_areas = @branch_coverage_areas.paginate(page: params[:page], per_page: 100)
        render layout: "admin_application"
      end

      format.csv { send_data @branch_coverage_areas.free_delivery_list_csv, filename: "free_delivery_list.csv" }
    end
  end

  def admin_suggested_restaurants_report
    @suggestions = SuggestRestaurant.includes(:user, :coverage_area, restaurant: :country)
    @countries = Country.where(id: @suggestions.map(&:restaurant).flatten.map(&:country_id).uniq).pluck(:name, :id)
    @suggestions = @suggestions.where(restaurants: { country_id: params[:searched_country_id] }) if params[:searched_country_id].present?
    @areas = CoverageArea.where(id: @suggestions.pluck(:coverage_area_id)).pluck(:area, :id).uniq.sort
    @suggestions = @suggestions.where(coverage_area_id: params[:searched_area_id]) if params[:searched_area_id].present?
    @suggestions = @suggestions.joins(:restaurant).where("restaurants.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?

    respond_to do |format|
      format.html do
        render layout: "admin_application"
      end

      format.csv { send_data @suggestions.suggested_list_csv, filename: "suggested_restaurants_list.csv" }
    end
  end

  def admin_amount_transfers_report
    @payments = BranchPayment.includes(branch: [restaurant: :country]).all
    @countries = @payments.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @payments = @payments.where(countries: { id: params[:country_id] }) if params[:country_id].present?
    @branches = Branch.where(id: @payments.pluck(:branch_id).uniq).pluck(:address, :id).sort
    @payments = @payments.where(branch_id: params[:searched_branch_id]) if params[:searched_branch_id].present?
    @payments = @payments.where("DATE(branch_payments.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @payments = @payments.where("DATE(branch_payments.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @payments = @payments.order(id: :desc)

    respond_to do |format|
      format.html do
        @payments = @payments.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @payments.payment_list_csv(params[:searched_branch_id], params[:start_date], params[:end_date]), filename: "payment_list.csv" }
    end
  end

  def admin_points_redeemed_report
    @orders = Order.joins(:user, :points, branch: { restaurant: :country }).includes(:user, :points, branch: :restaurant)
    @orders = @orders.where(restaurants: { country_id: @admin.country_id }) if @admin.class.name == "User"
    @countries = @orders.pluck("countries.name, countries.id").uniq.sort
    @restaurants = @orders.pluck("restaurants.title, restaurants.id").uniq.sort
    @orders = @orders.where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @orders = @orders.where(restaurants: { id: params[:restaurant_id] }) if params[:restaurant_id].present?
    @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @orders = @orders.where("orders.id = ? or branches.address like ? or users.name like ?", params[:keyword].to_s, "%#{params[:keyword]}%", "%#{params[:keyword]}%") if params[:keyword].present?
    @orders = @orders.where(order_type: params[:order_type]) if params[:order_type].present?
    @orders = @orders.distinct.order_by_date_desc
    @all_orders = @orders

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @orders.points_redeemed_report_csv(params[:country_id], params[:start_date], params[:end_date], "admin"), filename: "admin_points_redeemed_report.csv" }
    end
  end

  def admin_driver_review_report
    @ratings = Rating.active.includes(:branch, { order: :transporter }).joins(:branch, { order: :transporter }).distinct
    @companies = DeliveryCompany.where(id: @ratings.pluck("users.delivery_company_id").uniq).pluck(:name, :id).sort
    @restaurants = Restaurant.where(id: @ratings.pluck("branches.restaurant_id").uniq).pluck(:title, :id).sort
    @ratings = @ratings.where(users: { delivery_company_id: params[:searched_company_id] }) if params[:searched_company_id].present?
    @ratings = @ratings.where(branches: { restaurant_id: params[:searched_restaurant_id] }) if params[:searched_restaurant_id].present?
    @ratings = @ratings.where("orders.id = ? OR users.name like ?", params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
    @ratings = @ratings.where("DATE(ratings.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @ratings = @ratings.where("DATE(ratings.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @ratings = @ratings.order(id: :desc)
    @all_ratings = @ratings

    respond_to do |format|
      format.html do
        @ratings = @ratings.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @ratings.admin_driver_rating_csv(params[:searched_company_id], params[:searched_restaurant_id], params[:start_date], params[:end_date]), filename: "admin_driver_rating.csv" }
    end
  end

  def admin_delete_driver_review
    rating = Rating.find(params[:rating_id])
    rating.update(driver_hidden: true)
    flash[:success] = "Driver Review Successfully Deleted"
    redirect_to request.referer
  end

  def admin_transporter_timings_report
    @transporters = User.joins(:auths).includes(:delivery_company, :zones, branches: :restaurant).where(auths: { role: "transporter" }).reject_ghost_driver
    @companies = DeliveryCompany.where(id: @transporters.pluck(:delivery_company_id).uniq).pluck(:name, :id).sort
    @restaurants = @transporters.joins(branches: :restaurant).distinct.pluck("restaurants.title, restaurants.id").sort
    @zones = @transporters.joins(:zones).distinct.pluck("zones.name, zones.id").sort
    @transporters = @transporters.where(delivery_company_id: params[:searched_company_id]) if params[:searched_company_id].present?
    @transporters = @transporters.where(branches: { restaurant_id: params[:searched_restaurant_id] }) if params[:searched_restaurant_id].present?
    @transporters = @transporters.where(zones: { id: params[:searched_zone_id] }) if params[:searched_zone_id].present?
    @transporters = @transporters.where("users.cpr_number = ? OR users.id = ? OR users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
    @transporters = @transporters.order(:id)

    respond_to do |format|
      format.html do
        @transporters = @transporters.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @transporters.admin_driver_list_csv, filename: "admin_driver_list.csv" }
    end
  end

  def admin_driver_timings
    @user = User.find(params[:user_id])
    @timings = @user.transporter_timings.order(id: :desc)
    @timings = @timings.where("DATE(transporter_timings.created_at) >= ? AND DATE(transporter_timings.created_at) <= ?", (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date)

    respond_to do |format|
      format.html do
        @timings = @timings.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @timings.driver_timing_list_csv(@user, (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date), filename: "driver_timing_list.csv" }
    end
  end

  def admin_driver_performance_report
    @start_date = (params[:start_date].presence || Date.today - 30).to_date
    @end_date = (params[:end_date].presence || Date.today).to_date
    @transporters = User.joins(:auths).includes(:order_transporters, :transporter_timings, :delivery_company, :zones, branches: :restaurant).where(auths: { role: "transporter" }).reject_ghost_driver.distinct
    @companies = DeliveryCompany.where(id: @transporters.pluck(:delivery_company_id).uniq).pluck(:name, :id).sort
    @restaurants = @transporters.joins(branches: :restaurant).distinct.pluck("restaurants.title, restaurants.id").sort
    @transporters = @transporters.where(delivery_company_id: params[:searched_company_id]) if params[:searched_company_id].present?
    @transporters = @transporters.where(branches: { restaurant_id: params[:searched_restaurant_id] }) if params[:searched_restaurant_id].present?
    @transporters = @transporters.where("users.cpr_number = ? OR users.id = ? OR users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
    @transporters = @transporters.order(:id)

    respond_to do |format|
      format.html do
        @transporters = @transporters.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @transporters.admin_driver_performance_report_csv(@start_date, @end_date), filename: "admin_driver_performance_report.csv" }
    end
  end

  def admin_suggested_restaurants_users
    @restaurant = Restaurant.find(params[:restaurant_id])
    @area = CoverageArea.find(params[:area_id])
    user_ids = SuggestRestaurant.where(restaurant_id: @restaurant.id, coverage_area_id: @area.id).pluck(:user_id).uniq.compact
    @users = User.where(id: user_ids)

    respond_to do |format|
      format.js {}
      format.csv { send_data @users.restaurant_suggestion_list_csv(@restaurant.title, @area.area), filename: "suggested_restaurants_users_list.csv" }
    end
  end

  def send_suggested_restaurants_push_notification
    @restaurant = Restaurant.find(params[:restaurant_id])
    @area = CoverageArea.find(params[:area_id])
    user_ids = SuggestRestaurant.where(restaurant_id: @restaurant.id, coverage_area_id: @area.id).pluck(:user_id).uniq.compact
    @users = User.where(id: user_ids)
  end

  def send_suggested_restaurants_user_push_notification
    @restaurant = Restaurant.find(params[:restaurant_id])
    @area = CoverageArea.find(params[:area_id])
    user_ids = SuggestRestaurant.where(restaurant_id: @restaurant.id, coverage_area_id: @area.id).pluck(:user_id).uniq.compact
    @users = User.where(id: user_ids)

    @users.each do |user|
      fire_single_notification(params[:title], params[:description], params[:image], user.email)
      EmailOnPushNotification.perform_async(user.email, params[:title], params[:description])
    end

    flash[:success] = "Notifications and Mail Sent Successfully!"
    redirect_to request.referer
  end

  def delivery_settle_amount_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @companies = DeliveryCompany.where(approved: true).order(:name)
    @searched_company_id = params[:searched_company_id].presence

    company_ids = if @searched_company_id
                    DeliveryCompany.where(id: @searched_company_id)
                  else
                    DeliveryCompany.all
                  end

    company_ids = company_ids.where(country_id: params[:country_id]) if params[:country_id].present?
    @transporters = User.joins(:auths).where(auths: { role: "transporter" }, delivery_company_id: company_ids.pluck(:id))
    @all_orders = Order.settle_amount_list_report(@transporters.pluck(:id))
    @all_orders = Order.prepaid_settle_order_list(@transporters.pluck(:id)).where.not(id: @all_orders.pluck(:id)).order_by_date_desc if params[:type] == "online"
    @all_orders = @all_orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @all_orders = @all_orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @all_orders = @all_orders.order_by_date_desc

    respond_to do |format|
      format.html do
        @orders = @all_orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @all_orders.delivery_settle_amount_report_csv(params[:country_id]), filename: "delivery_settle_amount_report_#{params[:type]}.csv" }
    end
  end

  def restaurant_settle_amount_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @restaurants = Restaurant.joins(branches: :orders).where(is_signed: true, approved: true, branches: { is_approved: true }).where.not(title: ["", nil]).distinct.order(:title)
    @restaurants = @restaurants.where(country_id: params[:country_id]) if params[:country_id].present?
    @searched_restaurant_id = params[:searched_restaurant_id].presence

    branch_ids = if @searched_restaurant_id
                   Restaurant.find(@searched_restaurant_id).branches.pluck(:id)
                 else
                   Branch.joins(:restaurant).where(restaurants: { id: @restaurants.pluck(:id).uniq }).pluck(:id)
                 end

    @all_orders = restaurant_settle_amount_data(branch_ids, params[:start_date], params[:end_date], "cash", params[:status])
    @all_orders = restaurant_settle_amount_data(branch_ids, params[:start_date], params[:end_date], "online", params[:status]).where.not(id: @all_orders.pluck(:id)).order_by_date_desc if params[:type] == "online"
    @all_orders = @all_orders.order_by_date_desc

    respond_to do |format|
      format.html do
        @orders = @all_orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @all_orders.restaurant_settle_amount_report_csv(params[:type], params[:country_id]), filename: "restaurant_settle_amount_report_#{params[:type]}.csv" }
    end
  end

  def restaurant_delivery_transaction_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @restaurants = Restaurant.joins(branches: :orders).where(is_signed: true, approved: true, branches: { is_approved: true }).where.not(title: ["", nil]).distinct.order(:title)
    @restaurants = @restaurants.where(country_id: params[:country_id]) if params[:country_id].present?
    @searched_restaurant_id = params[:searched_restaurant_id].presence

    branch_ids = if @searched_restaurant_id
                   Restaurant.find(@searched_restaurant_id).branches.pluck(:id)
                 else
                   Branch.joins(:restaurant).where(restaurants: { id: @restaurants.pluck(:id).uniq }).pluck(:id)
                 end

    @all_orders = restaurant_delivery_transaction_data(branch_ids, params[:start_date], params[:end_date], "cash", params[:status])
    @all_orders = restaurant_delivery_transaction_data(branch_ids, params[:start_date], params[:end_date], "online", params[:status]).where.not(id: @all_orders.pluck(:id)).order_by_date_desc if params[:type] == "online"
    @all_orders = @all_orders.order_by_date_desc

    respond_to do |format|
      format.html do
        @orders = @all_orders.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @all_orders.restaurant_delivery_transaction_report_csv(params[:type], params[:country_id]), filename: "restaurant_delivery_transaction_report_#{params[:type]}.csv" }
    end
  end

  def admin_branch_charges_report
    @branches = Branch.joins(:restaurant).where(is_approved: true, restaurants: { is_signed: true }).distinct.includes(:branch_subscription, :report_subscription, restaurant: :country)
    @branches = @branches.where(restaurants: { country_id: @admin.country_id }) if @admin.class.name == "User"
    @restaurants = Restaurant.where(id: @branches.pluck(:restaurant_id)).pluck(:title, :id).sort
    @branches = @branches.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    @branches = @branches.where("address like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @branches = @branches.order("restaurants.title")

    respond_to do |format|
      format.html do
        @branches = @branches.paginate(page: params[:page], per_page: 100)
        render layout: "admin_application"
      end

      format.csv { send_data @branches.branch_charges_report_csv, filename: "branch_charges_report.csv" }
    end
  end

  def admin_user_cart_report
    @carts = Cart.joins(:cart_items).where.not(user_id: nil, branch_id: nil).includes(:cart_items, :user, :coverage_area, branch: :restaurant)
    @countries = @carts.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @carts = @carts.where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @restaurants = Restaurant.where(id: @carts.map(&:branch).flatten.uniq.map(&:restaurant_id).flatten.uniq).pluck(:title, :id).sort
    @areas = CoverageArea.where(id: @carts.pluck(:coverage_area_id).uniq).pluck(:area, :id).sort
    @carts = @carts.filter_by_query(params[:restaurant_id], params[:area_id], params[:keyword], params[:start_date], params[:end_date]).distinct.order(updated_at: :desc)
    @all_carts = @carts

    respond_to do |format|
      format.html do
        @carts = @carts.paginate(page: params[:page], per_page: 100)
        render layout: "admin_application"
      end

      format.csv { send_data @carts.list_csv, filename: "cart_list.csv" }
    end
  end

  def user_cart_push_notification
    @cart_ids = params[:cart_ids]
  end

  def send_user_cart_push_notification
    @cart_ids = params[:cart_ids].split(" ")

    @cart_ids.each do |cart_id|
      cart = Cart.find(cart_id)

      if cart.user&.email
        fire_single_notification(params[:title], params[:description], params[:image], cart.user.email)
        EmailOnPushNotification.perform_async(cart.user.email, params[:title], params[:description])
      end
    end

    flash[:success] = "Notifications and Mail Sent Successfully!"
    redirect_to request.referer
  end

  def edit_order_transferrable_amount
    @order = Order.find(params[:order_id])
  end

  def update_order_transferrable_amount
    @order = Order.find(params[:order_id])
    @order.update(transferrable_amount: params[:transferrable_amount]) if params[:transferrable_amount].present?
    flash[:success] = "Transferrable Amount Successfully Updated!"
    redirect_to request.referer
  end

  def admin_mark_order_as_paid
    order = Order.find(params[:order_id])
    order.update(paid_by_admin: true, paid_by_admin_at: Time.zone.now)
    order_branch = order.branch
    transfer_amount = order.transferrable_amount.presence || order.third_party_payable_amount_business_all
    order_branch.update(pending_amount: (order_branch.pending_amount + transfer_amount).to_f.round(3))
    flash[:success] = "Order Marked as Paid!"
    redirect_to request.referer
  end

  def admin_mark_bulk_order_as_paid
    orders = Order.where(id: params[:bulk_order_ids])

    if orders.present?
      orders.each do |order|
        order.update(paid_by_admin: true, paid_by_admin_at: Time.zone.now)
        order_branch = order.branch
        transfer_amount = order.transferrable_amount.presence || order.third_party_payable_amount_business_all
        order_branch.update(pending_amount: (order_branch.pending_amount + transfer_amount).to_f.round(3))
      end

      flash[:success] = "Selected Orders Marked as Paid!"
    else
      flash[:error] = "Please Select an Order"
    end

    redirect_to request.referer
  end

  def admin_calendar_report
    @dates = EventDate.joins(:event).includes(:event)
    @dates = @dates.where("events.title like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @dates = @dates.where("DATE(start_date) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @dates = @dates.where("DATE(start_date) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @dates = @dates.distinct.order(start_date: :desc)
    @event_data = event_calendar_order_date(@dates)

    respond_to do |format|
      format.html do
        @event_data = @event_data.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.csv { send_data @dates.calendar_report_csv(params[:start_date], params[:end_date]), filename: "calendar_report.csv" }
    end
  end

  def admin_calendar_restaurant_report
    @event_date = EventDate.find(params[:event_date_id])

    if @event_date.end_date.nil?
      @orders = Order.where("DATE(created_at) = ? and is_delivered = true", @event_date.start_date)
    else
      @orders = Order.where("DATE(created_at) between ? AND ? and is_delivered = true", @event_date.start_date, @event_date.end_date)
    end

    respond_to do |format|
      format.js { }
      format.csv { send_data @orders.calendar_report_csv(@event_date), filename: "calendar_restaurant_sale_report.csv" }
    end
  end

  def admin_todays_report
    @data = []
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @branches = Branch.joins(:orders).where(orders: { is_settled: true, dine_in: false }).distinct
    @branches = @branches.includes(:restaurant).where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @restaurants = Restaurant.where(id: @branches.pluck(:restaurant_id).uniq).order(:title)
    @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
    @branches = @branches.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    @branches = @branches.where("branches.address like ?", "%#{params[:keyword]}%") if params[:keyword].present?

    Branch.joins(:restaurant).where(id: @branches.pluck(:id)).distinct.order("restaurants.title").each do |branch|
      @orders = Order.delivery_orders.where(is_settled: true, branch_id: branch.id)

      next if @orders.blank?
      @orders = @orders.where(area: params[:area]) if params[:area].present?
      @orders = @orders.where(third_party_delivery: (params[:delivery_type] == "true")) if params[:delivery_type].present?
      @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
      @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?

      @data << { country_name: branch.restaurant.country.name, restaurant_name: branch.restaurant.title, address: branch.address, cash_orders_count: @orders.cash_orders.count, cash_orders_amount: helpers.number_with_precision(@orders.cash_orders.sum(:total_amount)), online_orders_count: @orders.online_orders.count, online_orders_amount: helpers.number_with_precision(@orders.online_orders.sum(:total_amount)), total_orders_count: @orders.count, total_orders_amount: helpers.number_with_precision(@orders.sum(:total_amount)) }
    end

    @all_data = @data
    @country_name = params[:country_id].present? ? Country.find(params[:country_id]).name : "All Countries"
    @restaurant_name = params[:restaurant_id].present? ? Restaurant.find(params[:restaurant_id]).title : "All Restaurants"
    @delivery_type = params[:delivery_type].present? ? (params[:delivery_type] == "true" ? "Food Club Delivery" : "Restaurant Delivery") :"All Delivery"
    @area_name = params[:area].presence || "All Areas"
    @start_date = params[:start_date].presence || "NA"
    @end_date = params[:end_date].presence || "NA"

    respond_to do |format|
      format.html do
        @data = @data.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.xlsx { render xlsx: "admin_todays_reports_csv", filename: "Todays Report.xlsx" }
    end
  end

  def admin_most_selling_item_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @branches = Branch.joins(:orders).where(orders: { is_settled: true, dine_in: false }).distinct
    @branches = @branches.includes(:restaurant).where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @restaurants = Restaurant.where(id: @branches.pluck(:restaurant_id).uniq).order(:title)
    @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
    @branches = @branches.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    @branches = @branches.where("branches.address like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @items = admin_get_area_wise_top_selling_items(@branches, params[:area], params[:start_date], params[:end_date], params[:delivery_type])
    @country_name = params[:country_id].present? ? Country.find(params[:country_id]).name : "All Countries"
    @restaurant_name = params[:restaurant_id].present? ? Restaurant.find(params[:restaurant_id]).title : "All Restaurants"
    @delivery_type = params[:delivery_type].present? ? (params[:delivery_type] == "true" ? "Food Club Delivery" : "Restaurant Delivery") :"All Delivery"
    @area_name = params[:area].presence || "All Areas"
    @start_date = params[:start_date].presence || "NA"
    @end_date = params[:end_date].presence || "NA"

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.xlsx { render xlsx: "admin_most_selling_item_report_csv", filename: "Top Selling Items Report.xlsx" }
    end
  end

  def admin_area_wise_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @branches = Branch.joins(:orders).where(orders: { is_settled: true, dine_in: false }).distinct
    @branches = @branches.includes(:restaurant).where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @restaurants = Restaurant.where(id: @branches.pluck(:restaurant_id).uniq).order(:title)
    @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
    @branches = @branches.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    @branches = @branches.where("branches.address like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @area_wise = get_area_wise_report(@branches, params[:area], nil, params[:start_date], params[:end_date])
    @country_name = params[:country_id].present? ? Country.find(params[:country_id]).name : "All Countries"
    @restaurant_name = params[:restaurant_id].present? ? Restaurant.find(params[:restaurant_id]).title : "All Restaurants"
    @area_name = params[:area].presence || "All Areas"
    @start_date = params[:start_date].presence || "NA"
    @end_date = params[:end_date].presence || "NA"
    @all_area_wise = @area_wise

    respond_to do |format|
      format.html do
        @area_wise = @area_wise.paginate(page: params[:page], per_page: 50)
        render layout: "admin_application"
      end

      format.xlsx { render xlsx: "admin_area_wise_order_reports_csv", filename: "Area wise Orders Report.xlsx" }
    end
  end

  def admin_top_customer_report
    @countries = Order.joins(branch: { restaurant: :country }).pluck("countries.name, countries.id").uniq.sort
    @branches = Branch.joins(:orders).where(orders: { is_settled: true, dine_in: false }).distinct
    @branches = @branches.includes(:restaurant).where(restaurants: { country_id: params[:country_id] }) if params[:country_id].present?
    @restaurants = Restaurant.where(id: @branches.pluck(:restaurant_id).uniq).order(:title)
    @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
    @branches = @branches.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    @branches = @branches.where("branches.address like ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @customers = admin_get_top_customer_reports(@branches, nil, params[:start_date], params[:end_date], params[:area])
    @country_name = params[:country_id].present? ? Country.find(params[:country_id]).name : "All Countries"
    @restaurant_name = params[:restaurant_id].present? ? Restaurant.find(params[:restaurant_id]).title : "All Restaurants"
    @area_name = params[:area].presence || "All Areas"
    @start_date = params[:start_date].presence || "NA"
    @end_date = params[:end_date].presence || "NA"

    respond_to do |format|
      format.html { render layout: "admin_application" }
      format.xlsx { render xlsx: "admin_top_customer_reports_csv", filename: "Top Customer Report.xlsx" }
    end
  end
end
