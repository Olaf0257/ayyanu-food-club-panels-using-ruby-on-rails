class Business::ReportsController < ApplicationController
  before_action :authenticate_business

  def todays_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @data = []
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)

      Branch.where(id: (params[:branch].presence || @branches.pluck(:id))).each do |branch|
        @orders = Order.where(is_settled: true, branch_id: branch, order_type: ["prepaid", "postpaid"])
        @orders = @orders.where(area: params[:area]) if params[:area].present?
        @orders = @orders.where(third_party_delivery: (params[:third_party_delivery] == "true")) if params[:third_party_delivery].present?
        @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
        @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?

        @data << { address: branch.address, cash_orders_count: @orders.cash_orders.count, cash_orders_amount: helpers.number_with_precision(@orders.cash_orders.sum(:total_amount)), online_orders_count: @orders.online_orders.count, online_orders_amount: helpers.number_with_precision(@orders.online_orders.sum(:total_amount)), total_orders_count: @orders.count, total_orders_amount: helpers.number_with_precision(@orders.sum(:total_amount)) }
      end

      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @delivery_type = params[:third_party_delivery].present? ? (params[:third_party_delivery] == "true" ? "Third Party Delivery" : "Restaurant Delivery") : "All Delivery"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          render xlsx: "todays_reports_csv", filename: "Todays Report.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def top_selling_item
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @items = get_area_wise_top_selling_items(params[:branch], @branches, params[:area], params[:start_date], params[:end_date])
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          @data = @items
          render xlsx: "top_selling_item_csv", filename: "Top-Selling-Items-list.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def top_selling_item_csv
    @data = params[:items_data]

    respond_to do |format|
      format.html

      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Top-Selling-Items-list.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx { render xlsx: "top_selling_item_csv", filename: "Top-Selling-Items-list.xlsx" }
    end
  end

  def area_wise_report
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @area_wise = get_area_wise_report(@branches, params[:area], params[:branch], params[:start_date], params[:end_date])
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          @data = @area_wise
          render xlsx: "area_wise_csv", filename: "Area-wise-list.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def area_wise_csv
    @data = params[:items_data]

    respond_to do |format|
      format.html

      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Area-wise-list.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx { render xlsx: "area_wise_csv", filename: "Area-wise-list.xlsx" }
    end
  end

  def revenue_growth_lost_report
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @reports = revenue_lost_reports(@branches, params[:branch], params[:start_date], params[:end_date], params[:area]).paginate(page: params[:page], per_page: (params[:per_page].presence || 20))
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : @branches.first.address
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          @data = revenue_lost_reports(@branches, params[:branch], params[:start_date], params[:end_date], params[:area])
          render xlsx: "revenue_growth_lost_report_csv", filename: "Revenue-Growth-lost-report.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def revenue_growth_lost_report_csv
    @data = params[:items_data]

    respond_to do |format|
      format.html

      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Revenue-Growth-lost-report.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx { render xlsx: "revenue_growth_lost_report_csv", filename: "Revenue-Growth-lost-report.xlsx" }
    end
  end

  def branch_over_all_reportes
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @currentYear = Date.current.year
      @branches = @restaurant.branches.is_subscribed
      branch = params[:branch].present? ? get_branch(params[:branch]) : @branches.first
      serchKey = params[:search_key].presence || "month"
      @branch_orders_graph_data = get_branch_orders_graph_data(branch, serchKey)
      @branch_order_count_graph_data = get_branch_orders_count(branch, serchKey)
      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end
  end

  def budget_sales_report
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @budget_sales = get_budget_sales_report(@branches, params[:start_date], params[:end_date], params[:branch], params[:area])
      @data = @budget_sales
    else
      redirect_to business_partner_login_path
    end

    render layout: "partner_application"
  end

  def budget_sales_report_csv
    @data = params[:items_data]

    respond_to do |format|
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Budget-Vs-Sale-list-list.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx
    end

    render layout: "partner_application"
  end

  def top_customer_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @customers = get_top_customer_reports(@branches, params[:branch], params[:start_date], params[:end_date], params[:area])
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          @data = @customers
          render xlsx: "top_customer_reports_csv", filename: "Top-Customer.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def top_customer_reports_csv
    @data = params[:items_data]

    respond_to do |format|
      format.html

      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Top-Customer-list.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx { render xlsx: "top_customer_reports_csv", filename: "Top-Customer.xlsx" }
    end
  end

  def new_customer_report
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @data = get_new_customer_data(@branches, params[:branch], params[:start_date], params[:end_date], params[:area])
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          render xlsx: "new_customer_report_csv", filename: "New-customer-data.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def new_customer_report_csv
    @data = params[:items_data]

    respond_to do |format|
      format.html

      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"New-customer-data.csv\""
        headers["Content-Type"] ||= "text/csv"
      end

      format.xlsx { render xlsx: "new_customer_report_csv", filename: "New-customer-data.xlsx" }
    end
  end

  def settlement_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      branch_ids = @branches.pluck(:id)
      @all_orders = restaurant_settle_amount_data(branch_ids, params[:start_date], params[:end_date], "cash", params[:status])
      @all_orders = restaurant_settle_amount_data(branch_ids, params[:start_date], params[:end_date], "online", params[:status]).where.not(id: @all_orders.pluck(:id)) if params[:type] == "online"
      @all_orders = @all_orders.where(branch_id: params[:branch]) if params[:branch].present?
      @all_orders = @all_orders.order_by_date_desc

      respond_to do |format|
        format.html do
          @orders = @all_orders.paginate(page: params[:page], per_page: 50)
          render layout: "partner_application"
        end

        format.csv { send_data @all_orders.business_settle_amount_report_csv(params[:type]), filename: "restaurant_settle_amount_report_#{params[:type]}.csv" }
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def transaction_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      branch_ids = @branches.pluck(:id)
      @all_orders = restaurant_delivery_transaction_data(branch_ids, params[:start_date], params[:end_date], "cash", params[:status])
      @all_orders = restaurant_delivery_transaction_data(branch_ids, params[:start_date], params[:end_date], "online", params[:status]).where.not(id:   @all_orders.pluck(:id)) if params[:type] == "online"
      @all_orders = @all_orders.where(branch_id: params[:branch]) if params[:branch].present?
      @all_orders = @all_orders.order_by_date_desc

      respond_to do |format|
        format.html do
          @orders = @all_orders.paginate(page: params[:page], per_page: 50)
          render layout: "partner_application"
        end

        format.csv { send_data @all_orders.business_transaction_report_csv(params[:type]), filename: "restaurant_delivery_transaction_report_#{params[:type]}.csv" }
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def delivery_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @data = []
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)

      Branch.where(id: (params[:branch].presence || @branches.pluck(:id))).each do |branch|
        @orders = Order.where(is_settled: true, branch_id: branch, third_party_delivery: false, order_type: ["prepaid", "postpaid"])
        @orders = @orders.where(area: params[:area]) if params[:area].present?
        @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
        @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?

        @data << { address: branch.address, cash_orders_count: @orders.cash_orders.count, cash_delivery_amount: helpers.number_with_precision(@orders.cash_orders.sum(:delivery_charge)), online_orders_count: @orders.online_orders.count, online_delivery_amount: helpers.number_with_precision(@orders.online_orders.sum(:delivery_charge)), total_orders_count: @orders.count, total_delivery_amount: helpers.number_with_precision(@orders.sum(:delivery_charge)) }
      end

      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          render xlsx: "delivery_reports_csv", filename: "Delivery Report.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def review_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @ratings = Rating.includes(:user, :branch, :order).where(branch_id: @branches.pluck(:id))
      @ratings = @ratings.where(branch_id: params[:branch]) if params[:branch].present?
      @ratings = @ratings.where(orders: { area: params[:area] }) if params[:area].present?
      @ratings = @ratings.where("DATE(ratings.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
      @ratings = @ratings.where("DATE(ratings.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
      @ratings = @ratings.order(created_at: :desc)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_ratings = @ratings

      respond_to do |format|
        format.html do
          @ratings = @ratings.paginate(page: params[:page], per_page: 50)
          render layout: "partner_application"
        end

        format.xlsx do
          render xlsx: "review_reports_csv", filename: "Review Report.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def driver_review_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches.is_subscribed
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @ratings = Rating.active.includes(:branch, { order: :transporter }).joins(:branch, { order: :transporter }).where(branch_id: @branches.pluck(:id)).where("users.delivery_company_id is null").distinct
      @ratings = @ratings.where(branch_id: params[:branch]) if params[:branch].present?
      @ratings = @ratings.where(orders: { area: params[:area] }) if params[:area].present?
      @ratings = @ratings.where("orders.id = ? OR users.name like ?", params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
      @ratings = @ratings.where("DATE(ratings.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
      @ratings = @ratings.where("DATE(ratings.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
      @ratings = @ratings.order(created_at: :desc)
      @branch_name = params[:branch].present? ? Branch.find(params[:branch]).address : "All Branches"
      @area_name = params[:area].presence || "All Areas"
      @start_date = params[:start_date].presence || "NA"
      @end_date = params[:end_date].presence || "NA"
      @all_ratings = @ratings

      respond_to do |format|
        format.html do
          @ratings = @ratings.paginate(page: params[:page], per_page: 50)
          render layout: "partner_application"
        end

        format.xlsx do
          render xlsx: "driver_review_reports_csv", filename: "Driver Review Report.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def driver_timing_report
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @transporters = User.joins(branch_transports: :branch).where("restaurant_id = ?", @restaurant.id).distinct
      @transporters = @transporters.where("users.cpr_number = ? OR users.id = ? OR users.name like ?", params[:keyword], params[:keyword], "%#{params[:keyword]}%") if params[:keyword].present?
      @transporters = @transporters.order(:id).paginate(page: params[:page], per_page: 50)
      render layout: "partner_application"
    else
      redirect_to business_partner_login_path
    end
  end

  def driver_timing
    @transporter = User.find(params[:user_id])
    @timings = @transporter.transporter_timings.order(id: :desc)
    @timings = @timings.where("DATE(transporter_timings.created_at) >= ? AND DATE(transporter_timings.created_at) <= ?", (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date)

    respond_to do |format|
      format.html do
        @timings = @timings.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @timings.driver_timing_list_csv(@transporter, (params[:start_date].presence || Date.today).to_date, (params[:end_date].presence || Date.today).to_date), filename: "driver_timing_list.csv" }
    end
  end

  def points_redeemed_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @branches = @restaurant.branches.is_subscribed
    @orders = Order.joins(:points, branch: :restaurant).includes(:user, :points, branch: :restaurant).where(branch_id: @branches.pluck(:id))
    @orders = @orders.where("DATE(orders.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    @orders = @orders.where("DATE(orders.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    @orders = @orders.where("orders.id = ? or branches.address like ?", params[:keyword].to_s, "%#{params[:keyword]}%") if params[:keyword].present?
    @orders = @orders.distinct.order_by_date_desc
    @all_orders = @orders

    respond_to do |format|
      format.html do
        @orders = @orders.paginate(page: params[:page], per_page: 50)
        render layout: "partner_application"
      end

      format.csv { send_data @orders.points_redeemed_report_csv(params[:country_id], params[:start_date], params[:end_date], "business"), filename: "admin_points_redeemed_report.csv" }
    end
  end

  def cancel_order_reports
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))

    if @restaurant
      @branches = @restaurant.branches
      @areas = get_branches_coverage_area(@branches).uniq.sort_by(&:area)
      @data = get_rejected_order_report(@branches, params[:branch], params[:area], params[:start_date], params[:end_date])

      respond_to do |format|
        format.html { render layout: "partner_application" }

        format.xlsx do
          render xlsx: "cancel_order_csv", filename: "Rejected-Order-list.xlsx"
        end
      end
    else
      redirect_to business_partner_login_path
    end
  end

  def cancel_order_csv
    @data = params[:items_data]
    respond_to do |format|
      format.html
      format.csv do
        headers["Content-Disposition"] = "attachment; filename=\"Cancel-Order-list.csv\""
        headers["Content-Type"] ||= "text/csv"
      end
      format.xlsx { render xlsx: "cancel_order_csv", filename: "Cancel-Order-list.xlsx" }
    end
  end

  # def budget_vs_sales_csv
  #   @data = params[:budget]
  #   p "-----------------"
  #   p params[:budget_sales]
  #   p @data
  #      respond_to do |format|
  #       format.html
  #       format.csv do
  #         headers['Content-Disposition'] = "attachment; filename=\"Budget-Vs-Sale-list-list.csv\""
  #         headers['Content-Type'] ||= 'text/csv'
  #       end
  #          format.xlsx {render xlsx: 'budget_vs_sales_csv',filename: "Budget-Vs-Sale-list.xlsx"}
  #       end
  # end

  def business_busy_restaurants
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @busy = get_business_busy_restaurant(@restaurant.id).paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
  end

  def business_close_restaurants
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    @close = get_business_close_restaurant(@restaurant.id).paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
  end

  def pos_customer_master
    render layout: 'partner_application'
  end

  def pos_brand_master
    render layout: 'partner_application'
  end

  def pos_employee_master
    render layout: 'partner_application'
  end

  def pos_setup_master
    render layout: 'partner_application'
  end

  def manager_busy_restaurants
    @branch = BranchCoverageArea.find_by(id: decode_token(params[:branch_id]))
    @busy = get_manager_busy_restaurant(@branch.id).paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
  end

  def manager_close_restaurants
    @branch = BranchCoverageArea.find_by(id: decode_token(params[:branch_id]))
    @close = get_manager_close_restaurant(@branch.id).paginate(page: params[:page], per_page: params[:per_page])
    render layout: "partner_application"
  end
end
