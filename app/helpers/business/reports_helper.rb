module Business::ReportsHelper
  def get_top_selling_items(branch, all_branch)
    branch = branch.presence || all_branch.first.id
    orders = OrderItem.joins(:order, :menu_item).where("orders.branch_id = (?)", branch).group("menu_item_id").order("COUNT(menu_item_id) desc").count("menu_item_id")
    itemReportData = get_items_report(orders, branch)
    rescue Exception => e
  end

  def get_items_report(orders, branch)
    result = []
    orders.each do |order|
      next unless result.count < 10
      menuItem = MenuItem.find(order.first)
      orderCount = order.last
      totalOrder = Order.where("branch_id = ? ", branch)
      percentage = ((orderCount.to_f * 100) / totalOrder.count.to_f)
      # p percentage
      result << { id: menuItem.id, item_name: menuItem.item_name, item_rating: menuItem.item_rating, price_per_item: menuItem.price_per_item, totalItemCount: orderCount, percentage: helpers.number_with_precision(percentage, precision: 3) }
    end
    # p result
    result
  end

  def get_business_close_restaurant(restaurant_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_closed = ? and restaurant_id = ?", true, restaurant_id)
  end

  def get_business_busy_restaurant(restaurant_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_busy = ? and restaurant_id = ?", true, restaurant_id)
  end

  def get_manager_close_restaurant(branch_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_closed = ? and branch_id = ?", true, branch_id)
  end

  def get_manager_busy_restaurant(branch_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_busy = ? and branch_id = ?", true, branch_id)
  end

  def get_new_customer_data(all_branch, branch, start_date, end_date, area)
    customerData = []

    if branch.present?
      branch = Branch.find_branch(branch.to_i)
      orders = Order.joins(:user).where("branch_id = ? and user_id NOT IN (?)", branch, [0])
      orders = orders.where(orders: { area: area }) if area.present?
      orders = orders.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
      orders = orders.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
      customerData << { id: branch.id, branch_address: branch.address, total_order_count: orders.count, total_amount: helpers.number_with_precision(orders.pluck(:total_amount).sum, precision: 3), customer_count: orders.pluck(:user_id).uniq.count }
    else
      all_branch.each do |branch|
        orders = Order.joins(:user).where("branch_id = ? and user_id NOT IN (?)", branch, [0])
        orders = orders.where(orders: { area: area }) if area.present?
        orders = orders.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
        orders = orders.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
        customerData << { id: branch.id, branch_address: branch.address, total_order_count: orders.count, total_amount: helpers.number_with_precision(orders.pluck(:total_amount).sum, precision: 3), customer_count: orders.pluck(:user_id).uniq.count }
      end
    end

    customerData
  end

  def get_new_customer_order(branch, user_ids)
    Order.joins(:user).where("branch_id = ? and user_id NOT IN (?)", branch.id, user_ids)
  end

  def order_branch_wise(branch)
    Order.where("branch_id = ? ", branch)
  end

  def get_revenue_reports(branch)
    data = []
    if branch.present?
      currentMonthOrders = Order.current_month_completed_order.where("branch_id = ? ", branch)
      lastMonthOrders = Order.last_month_completed_order.where("branch_id = ? ", branch)
      total_current_month = currentMonthOrders.pluck(:total_amount).sum
      total_last_month = lastMonthOrders.pluck(:total_amount).sum
      branch = Branch.find_branch(branch)
      percentage = total_current_month > 0 ? total_last_month > 0 ? ((total_current_month - total_last_month) * 100) / total_last_month : 0.000 : 0.000
      status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Loss" : "#{helpers.number_with_precision(percentage, precision: 3)} % Profit"
      data << { id: branch.id, address: branch.address, current_month_order: currentMonthOrders.count, last_month_order: lastMonthOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_month, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_month, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3), status: status }
      data
    else
      @branches.each do |branch|
        currentMonthOrders = Order.current_month_completed_order.where("branch_id = ? ", branch.id)
        lastMonthOrders = Order.last_month_completed_order.where("branch_id = ? ", branch.id)
        # p lastMonthOrders.pluck(:total_amount)
        # p currentMonthOrders.pluck(:total_amount)
        total_current_month = currentMonthOrders.pluck(:total_amount).sum
        total_last_month = lastMonthOrders.pluck(:total_amount).sum
        branch = Branch.find_branch(branch.id)
        percentage = total_current_month > 0 ? total_last_month > 0 ? ((total_current_month - total_last_month) * 100) / total_last_month : 0.000 : 0.000
        status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Loss" : "#{helpers.number_with_precision(percentage, precision: 3)} % Profit"
        data << { id: branch.id, address: branch.address, current_month_order: currentMonthOrders.count, last_month_order: lastMonthOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_month, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_month, precision: 3), percentage: helpers.number_with_precision(percentage), status: status }
      end
      data
    end
  end

  def get_cancel_order(branch, report_period)
    data = []
    case report_period
    when "weekly"
      if branch.present?
        currentWeekOrders = Order.get_current_week_order(branch)
        priviousWeekOrders = Order.get_perivious_week_order(branch)
        total_current_week = currentWeekOrders.pluck(:total_amount).sum
        total_last_week = priviousWeekOrders.pluck(:total_amount).sum
        branch = Branch.find_branch(branch)
        percentage = total_current_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000
        status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
        data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
        data
      else
        all_branche_cancel_order(data)
        data
      end
    when "monthly"
      if branch.present?
        currentWeekOrders = Order.get_current_month_cancel_order(branch)
        priviousWeekOrders = Order.get_perivious_month_cancel_order(branch)
        total_current_week = currentWeekOrders.pluck(:total_amount).sum
        total_last_week = priviousWeekOrders.pluck(:total_amount).sum
        branch = Branch.find_branch(branch)
        percentage = total_current_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000
        status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
        data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
        data
      else
        all_branche_cancel_month_order(data)
        data
      end
    when "yearly"
      if branch.present?
        currentWeekOrders = Order.get_current_year_cancel_order(branch)
        priviousWeekOrders = Order.get_perivious_year_cancel_order(branch)
        total_current_week = currentWeekOrders.pluck(:total_amount).sum
        total_last_week = priviousWeekOrders.pluck(:total_amount).sum
        branch = Branch.find_branch(branch)
        percentage = total_current_week > 0 ? total_last_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000 : 0.000
        status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
        data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
        data
      else
        all_branche_cancel_year_order(data)
        data
      end
    else
      all_branche_cancel_order(data)
      data
    end
  end

  def all_branche_cancel_order(data)
    # p "over all"
    data
    @branches.each do |branch|
      currentWeekOrders = Order.get_current_week_order(branch.id)
      priviousWeekOrders = Order.get_perivious_week_order(branch.id)
      total_current_week = currentWeekOrders.pluck(:total_amount).sum
      total_last_week = priviousWeekOrders.pluck(:total_amount).sum
      percentage = total_current_week > 0 ? total_last_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000 : 0.000
      status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
      data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
      data
    end
  end

  def all_branche_cancel_month_order(data)
    # p "over all"
    data
    @branches.each do |branch|
      currentWeekOrders = Order.get_current_month_cancel_order(branch)
      priviousWeekOrders = Order.get_perivious_month_cancel_order(branch)
      total_current_week = currentWeekOrders.pluck(:total_amount).sum
      total_last_week = priviousWeekOrders.pluck(:total_amount).sum
      percentage = total_current_week > 0 ? total_last_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000 : 0.000
      status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
      data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
      data
    end
  end

  def all_branche_cancel_year_order(data)
    # p "over all"
    data
    @branches.each do |branch|
      currentWeekOrders = Order.get_current_year_cancel_order(branch)
      priviousWeekOrders = Order.get_perivious_year_cancel_order(branch)
      total_current_week = currentWeekOrders.pluck(:total_amount).sum
      total_last_week = priviousWeekOrders.pluck(:total_amount).sum
      percentage = total_current_week > 0 ? total_last_week > 0 ? ((total_current_week - total_last_week) * 100) / total_last_week : 0.000 : 0.000
      status = percentage < 0 ? "#{helpers.number_with_precision(percentage, precision: 3)} % Increase" : "#{helpers.number_with_precision(percentage, precision: 3)} % Decrease"
      data << { id: branch.id, address: branch.address, current_order: currentWeekOrders.count, last_order: priviousWeekOrders.count, total_revenue_current_month: helpers.number_with_precision(total_current_week, precision: 3), total_revenue_last_month: helpers.number_with_precision(total_last_week, precision: 3), percentage: helpers.number_with_precision(percentage, precision: 3) }
      data
    end
  end

  def get_branch_orders_graph_data(branch, serch_key)
    todayDate = Date.today

    case serch_key
    when "month"
      @currentMonth_orders = get_current_month_order(branch, todayDate, "currentMonth_orders")
      @priviousyearMonth_orders = get_current_month_order(branch, todayDate, "last_year_month_order")
    when "halfyearly"
      @currentMonth_orders = get_current_year_halfyearly_order(branch, todayDate, "currentYear_halfyearly_orders")
      @priviousyearMonth_orders = get_current_year_halfyearly_order(branch, todayDate, "last_year_halfyearly_order")
    when "year"
      @currentMonth_orders = get_current_year_order(branch, todayDate, "current_year_orders")
      @priviousyearMonth_orders = get_current_year_order(branch, todayDate, "last_year_order")
    else
      @currentMonth_orders = {}
      @priviousyearMonth_orders = {}
    end

    result = []

    @currentMonth_orders.keys.reverse.each do |key|
      graphItem = {}
      graphItem["y"] = key
      graphItem["a"] = @currentMonth_orders[key]
      graphItem["b"] = @priviousyearMonth_orders[key]
      result << graphItem
    end

    result
  end

  def get_branch_orders_count(branch, serch_key)
    todayDate = Date.today

    case serch_key
    when "month"
      @currentMonth_orders = get_current_month_order_count(branch, todayDate, "currentMonth_orders")
      @priviousyearMonth_orders = get_current_month_order_count(branch, todayDate, "last_year_month_order")
    when "halfyearly"
      @currentMonth_orders = get_current_year_halfyearly_order_count(branch, todayDate, "currentYear_halfyearly_orders")
      @priviousyearMonth_orders = get_current_year_halfyearly_order_count(branch, todayDate, "last_year_halfyearly_order")
    when "year"
      @currentMonth_orders = get_current_year_order_count(branch, todayDate, "current_year_orders")
      @priviousyearMonth_orders = get_current_year_order_count(branch, todayDate, "last_year_order")
    else
      @currentMonth_orders = {}
      @priviousyearMonth_orders = {}
    end

    result = []

    @currentMonth_orders.keys.reverse.each do |key|
      graphItem = {}
      graphItem["y"] = key
      graphItem["a"] = @currentMonth_orders[key]
      graphItem["b"] = @priviousyearMonth_orders[key]
      result << graphItem
    end

    result
   end

  def get_current_month_order(branch, startdate, keyword)
    today = keyword == "currentMonth_orders" ? Order.joins(:branch).where("DATE(orders.created_at) = ? and branches.id = (?) and is_rejected = (?)", startdate, branch, false).sum(:total_amount).round(3) : Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months), branch, false).sum(:total_amount).round(3)

    yesterday = keyword == "currentMonth_orders" ? Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 1.day, branch, false).sum(:total_amount).round(3) : Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 1.day, branch, false).sum(:total_amount).round(3)

    week1 = branch_order_data(branch, startdate - 2.days, keyword)
    week2 = branch_order_data(branch, startdate - 9.days, keyword)
    week3 = branch_order_data(branch, startdate - 16.days, keyword)
    week4 = branch_order_data(branch, startdate - 23.days, keyword)
    @result = {}

    [today, yesterday, week1, week2, week3, week4].flatten.each_with_index do |totalAmount, index|
      @result[(startdate - index.days).strftime("%Y-%m-%d").to_s] = totalAmount.round(3)
    end

    @result
    end

  def branch_order_data(branch, startdate, keyword)
    case keyword
    when "currentMonth_orders"
      today = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate, branch, false).sum(:total_amount).round(3)
      yesterday = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 1.day, branch, false).sum(:total_amount).round(3)
      before3days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 2.days, branch, false).sum(:total_amount).round(3)
      before4days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 3.days, branch, false).sum(:total_amount).round(3)
      before5days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 4.days, branch, false).sum(:total_amount).round(3)
      before6days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 5.days, branch, false).sum(:total_amount).round(3)
      before7days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 6.days, branch, false).sum(:total_amount).round(3)
    when "last_year_month_order"
      today = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months), branch, false).sum(:total_amount).round(3)
      yesterday = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 1.day, branch, false).sum(:total_amount).round(3)
      before3days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 2.days, branch, false).sum(:total_amount).round(3)
      before4days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 3.days, branch, false).sum(:total_amount).round(3)
      before5days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 4.days, branch, false).sum(:total_amount).round(3)
      before6days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 5.days, branch, false).sum(:total_amount).round(3)
      before7days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 6.days, branch, false).sum(:total_amount).round(3)
       end
    [today, yesterday, before3days, before4days, before5days, before6days, before7days]
  end

  def get_current_year_halfyearly_order(branch, startdate, keyword)
    case keyword
    when "currentYear_halfyearly_orders"
      currentMonth = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", startdate.beginning_of_month, startdate.end_of_month, branch, false).sum(:total_amount).round(3)
      before1month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).beginning_of_month, (startdate - 1.month).end_of_month, branch, false).sum(:total_amount).round(3)
      before2month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).beginning_of_month, (startdate - 2.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before3month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).beginning_of_month, (startdate - 3.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before4month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).beginning_of_month, (startdate - 4.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before5month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).beginning_of_month, (startdate - 5.months).end_of_month, branch, false).sum(:total_amount).round(3)

    when "last_year_halfyearly_order"
      currentMonth = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months).beginning_of_month, (startdate - 12.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before1month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 1.month).beginning_of_month, ((startdate - 12.months) - 1.month).end_of_month, branch, false).sum(:total_amount).round(3)
      before2month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 2.months).beginning_of_month, ((startdate - 12.months) - 2.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before3month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 3.months).beginning_of_month, ((startdate - 12.months) - 3.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before4month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 4.months).beginning_of_month, ((startdate - 12.months) - 4.months).end_of_month, branch, false).sum(:total_amount).round(3)
      before5month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 5.months).beginning_of_month, ((startdate - 12.months) - 5.months).end_of_month, branch, false).sum(:total_amount).round(3)
       end
    @result = {}
    [currentMonth, before1month, before2month, before3month, before4month, before5month].each_with_index do |bookingsCount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = bookingsCount
    end
    @result
    end

  def get_current_year_order(branch, startdate, keyword)
    case keyword
    when "current_year_orders"
      currentMonth = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate.month, branch, false).sum(:total_amount).round(3)
      before1month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).month, branch, false).sum(:total_amount).round(3)
      before2month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).month, branch, false).sum(:total_amount).round(3)
      before3month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).month, branch, false).sum(:total_amount).round(3)
      before4month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).month, branch, false).sum(:total_amount).round(3)
      before5month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).month, branch, false).sum(:total_amount).round(3)
      before6month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 6.months).month, branch, false).sum(:total_amount).round(3)
      before7month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 7.months).month, branch, false).sum(:total_amount).round(3)
      before8month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 8.months).month, branch, false).sum(:total_amount).round(3)
      before9month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 9.months).month, branch, false).sum(:total_amount).round(3)
      before10month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 10.months).month, branch, false).sum(:total_amount).round(3)
      before11month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 11.months).month, branch, false).sum(:total_amount).round(3)
    when "last_year_order"
      currentMonth = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate.year - 1, startdate.month, branch, false).sum(:total_amount).round(3)
      before1month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).year - 1, (startdate - 1.month).month, branch, false).sum(:total_amount).round(3)
      before2month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).year - 1, (startdate - 2.months).month, branch, false).sum(:total_amount).round(3)
      before3month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).year - 1, (startdate - 3.months).month, branch, false).sum(:total_amount).round(3)
      before4month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).year - 1, (startdate - 4.months).month, branch, false).sum(:total_amount).round(3)
      before5month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).year - 1, (startdate - 5.months).month, branch, false).sum(:total_amount).round(3)
      before6month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 6.months).year - 1, (startdate - 6.months).month, branch, false).sum(:total_amount).round(3)
      before7month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 7.months).year - 1, (startdate - 7.months).month, branch, false).sum(:total_amount).round(3)
      before8month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 8.months).year - 1, (startdate - 8.months).month, branch, false).sum(:total_amount).round(3)
      before9month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 9.months).year - 1, (startdate - 9.months).month, branch, false).sum(:total_amount).round(3)
      before10month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 10.months).year - 1, (startdate - 10.months).month, branch, false).sum(:total_amount).round(3)
      before11month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 11.months).year - 1, (startdate - 11.months).month, branch, false).sum(:total_amount).round(3)
    end

    @result = {}

    [currentMonth, before1month, before2month, before3month, before4month, before5month, before6month, before7month, before8month, before9month, before10month, before11month].each_with_index do |bookingsCount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = bookingsCount
    end

    @result
   end

  def get_current_month_order_count(branch, startdate, keyword)
    today = keyword == "currentMonth_orders" ? Order.joins(:branch).where("DATE(orders.created_at) = ? and branches.id = (?) and is_rejected = (?)", startdate, branch, false).count : Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months), branch, false).count
    yesterday = keyword == "currentMonth_orders" ? Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 1.day, branch, false).count : Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 1.day, branch, false).count
    week1 = branch_order_data_count(branch, startdate - 2.days, keyword)
    week2 = branch_order_data_count(branch, startdate - 9.days, keyword)
    week3 = branch_order_data_count(branch, startdate - 16.days, keyword)
    week4 = branch_order_data_count(branch, startdate - 23.days, keyword)
    @result = {}
    [today, yesterday, week1, week2, week3, week4].flatten.each_with_index do |totalAmount, index|
      @result[(startdate - index.days).strftime("%Y-%m-%d").to_s] = totalAmount
    end
    @result

    # joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) >= (?) and branches.id = (?) and is_rejected = (?)",todayDate.beginning_of_month,todayDate.end_of_month,branch,false)
  end

  def branch_order_data_count(branch, startdate, keyword)
    case keyword
    when "currentMonth_orders"
      today = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate, branch, false).count
      yesterday = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 1.day, branch, false).count
      before3days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 2.days, branch, false).count
      before4days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 3.days, branch, false).count
      before5days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 4.days, branch, false).count
      before6days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 5.days, branch, false).count
      before7days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate - 6.days, branch, false).count
    when "last_year_month_order"
      today = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months), branch, false).count
      yesterday = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 1.day, branch, false).count
      before3days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 2.days, branch, false).count
      before4days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 3.days, branch, false).count
      before5days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 4.days, branch, false).count
      before6days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 5.days, branch, false).count
      before7days = Order.joins(:branch).where("DATE(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months) - 6.days, branch, false).count
       end
    [today, yesterday, before3days, before4days, before5days, before6days, before7days]
  end

  def get_current_year_halfyearly_order_count(branch, startdate, keyword)
    case keyword
    when "currentYear_halfyearly_orders"
      currentMonth = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", startdate.beginning_of_month, startdate.end_of_month, branch, false).count
      before1month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).beginning_of_month, (startdate - 1.month).end_of_month, branch, false).count
      before2month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).beginning_of_month, (startdate - 2.months).end_of_month, branch, false).count
      before3month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).beginning_of_month, (startdate - 3.months).end_of_month, branch, false).count
      before4month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).beginning_of_month, (startdate - 4.months).end_of_month, branch, false).count
      before5month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).beginning_of_month, (startdate - 5.months).end_of_month, branch, false).count

    when "last_year_halfyearly_order"
      currentMonth = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", (startdate - 12.months).beginning_of_month, (startdate - 12.months).end_of_month, branch, false).count
      before1month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 1.month).beginning_of_month, ((startdate - 12.months) - 1.month).end_of_month, branch, false).count
      before2month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 2.months).beginning_of_month, ((startdate - 12.months) - 2.months).end_of_month, branch, false).count
      before3month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 3.months).beginning_of_month, ((startdate - 12.months) - 3.months).end_of_month, branch, false).count
      before4month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 4.months).beginning_of_month, ((startdate - 12.months) - 4.months).end_of_month, branch, false).count
      before5month = Order.joins(:branch).where("DATE(orders.created_at) >= (?) and DATE(orders.created_at) <= (?) and branches.id = (?) and is_rejected = (?)", ((startdate - 12.months) - 5.months).beginning_of_month, ((startdate - 12.months) - 5.months).end_of_month, branch, false).count
       end
    @result = {}
    [currentMonth, before1month, before2month, before3month, before4month, before5month].each_with_index do |bookingsCount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = bookingsCount
    end
    @result
    end

  def get_current_year_order_count(branch, startdate, keyword)
    case keyword
    when "current_year_orders"
      currentMonth = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", startdate.month, branch, false).count
      before1month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).month, branch, false).count
      before2month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).month, branch, false).count
      before3month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).month, branch, false).count
      before4month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).month, branch, false).count
      before5month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).month, branch, false).count
      before6month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 6.months).month, branch, false).count
      before7month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 7.months).month, branch, false).count
      before8month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 8.months).month, branch, false).count
      before9month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 9.months).month, branch, false).count
      before10month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 10.months).month, branch, false).count
      before11month = Order.joins(:branch).where("MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 11.months).month, branch, false).count
    when "last_year_order"
      currentMonth = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate.year - 1), startdate.month, branch, false).count
      before1month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 1.month).year - 1, (startdate - 1.month).month, branch, false).count
      before2month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 2.months).year - 1, (startdate - 2.months).month, branch, false).count
      before3month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 3.months).year - 1, (startdate - 3.months).month, branch, false).count
      before4month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 4.months).year - 1, (startdate - 4.months).month, branch, false).count
      before5month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 5.months).year - 1, (startdate - 5.months).month, branch, false).count
      before6month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 6.months).year - 1, (startdate - 6.months).month, branch, false).count
      before7month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 7.months).year - 1, (startdate - 7.months).month, branch, false).count
      before8month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 8.months).year - 1, (startdate - 8.months).month, branch, false).count
      before9month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 9.months).year - 1, (startdate - 9.months).month, branch, false).count
      before10month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 10.months).year - 1, (startdate - 10.months).month, branch, false).count
      before11month = Order.joins(:branch).where("YEAR(orders.created_at) = ? and MONTH(orders.created_at) = (?) and branches.id = (?) and is_rejected = (?)", (startdate - 11.months).year - 1, (startdate - 11.months).month, branch, false).count
    end

    @result = {}

    [currentMonth, before1month, before2month, before3month, before4month, before5month, before6month, before7month, before8month, before9month, before10month, before11month].each_with_index do |bookingsCount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = bookingsCount
    end

    @result
  end

  def get_budget_sales_report(branches, start_date, end_date, branch_id, area)
    orders = branches_all_order(branches)

    if branch_id.present? && start_date.present? && end_date.present?
      data = budget_data_according_to_date(orders, start_date, end_date, branch_id, area)
    elsif start_date.present? && end_date.present?
      data = budget_over_all_date_wise(start_date, end_date, branches, orders, area)
    elsif branch_id.present?
      data = get_budget_data(branch_id, orders, area)
    else
      data = budget_over_all_data(branches, orders, area)
    end

    data
  end

  def get_branches_coverage_area(branches)
    area = []
    branches.each do |branch|
      area_id = branch.coverage_areas.pluck(:coverage_area_id)
      coverage_areas = CoverageArea.get_coverage_areas(area_id)
      coverage_areas.each do |ar|
        area << ar
      end
    end
    area
  end

  def admin_get_area_wise_top_selling_items(all_branch, area, start_date, end_date, delivery_type)
    branch = all_branch.pluck(:id)
    orders = OrderItem.joins(:order, :menu_item).where(orders: { branch_id: branch, is_settled: true, dine_in: false })
    orders = orders.where(orders: { area: area }) if area.present?
    orders = orders.where(orders: { third_party_delivery: (delivery_type == "true") }) if delivery_type.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
    orders = orders.group("menu_item_id").order("COUNT(menu_item_id) desc, menu_items.item_name").count("menu_item_id")
    itemReportData = admin_get_area_wise_items_report(orders, branch)
  end

  def admin_get_area_wise_items_report(orders, branch)
    result = []

    orders.each do |order|
      next unless result.count < 20
      menuItem = MenuItem.find(order.first)
      orderCount = order.last
      totalOrder = Order.where(branch_id: branch)
      percentage = ((orderCount.to_f * 100) / totalOrder.count.to_f)
      result << { id: menuItem.id, item_name: menuItem.item_name, item_rating: menuItem.item_rating, price_per_item: menuItem.price_per_item, totalItemCount: orderCount, percentage: helpers.number_with_precision(percentage, precision: 3) }
    end

    result
  end

  def get_area_wise_top_selling_items(branch, all_branch, area, start_date, end_date)
    branch = branch.presence || all_branch.pluck(:id)
    orders = OrderItem.joins(:order, :menu_item).where(orders: { branch_id: branch })
    orders = orders.where(orders: { area: area }) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
    orders = orders.group("menu_item_id").order("COUNT(menu_item_id) desc").count("menu_item_id")
    itemReportData = get_area_wise_items_report(orders, branch)
  end

  def get_area_wise_items_report(orders, branch)
    result = []

    orders.each do |order|
      next unless result.count < 10
      menuItem = MenuItem.find(order.first)
      orderCount = order.last
      totalOrder = Order.where(branch_id: branch)
      percentage = ((orderCount.to_f * 100) / totalOrder.count.to_f)
      result << { id: menuItem.id, item_name: menuItem.item_name, item_rating: menuItem.item_rating, price_per_item: menuItem.price_per_item, totalItemCount: orderCount, percentage: helpers.number_with_precision(percentage, precision: 3) }
    end

    result
  end

  def get_area_wise_report(branches, area, branch, start_date, end_date)
    orders = branches_all_order(branches)
    orders = orders.where(branch_id: branch) if branch.present?
    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
    data = get_area_report_data(orders)
  end

  def branches_all_order(branches)
    Order.includes(branch: :restaurant).where("branch_id IN (?) and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branches.pluck(:id), true, true, true, true, false, true)
  end

  def get_area_report_data(orders)
    data = []
    coverage_areas = orders.present? ? orders.pluck(:area).uniq : []

    coverage_areas.each do |area|
      a = CoverageArea.where(area: area).first
      order = orders.where(area: area)
      total = order.pluck(:total_amount).sum
      data << { id: a&.id, area: area, total_amount: helpers.number_with_precision(total, precision: 3), total_order: order.count }
    end

    data
  end

  def get_budget_data(branch_id, orders, area)
    data = []
    budgetes = Budget.where(branch_id: branch_id)

    budgetes.each do |budget|
      orders = Order.where("branch_id = ? and DATE(created_at) >= (?) and DATE(created_at)  <= (?)and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branch_id, budget.start_date, budget.end_date, true, true, true, true, false, true)
      orders = orders.where(area: area) if area.present?
      total_order_amount = orders.pluck(:total_amount).sum
      budget_total_amount = budget.amount
      diffrence_amount = total_order_amount - budget_total_amount
      status = diffrence_amount > 0 ? "Profit" : "loss"
      address = budget.branch.address
      data << { address: address, order_count: orders.count, start_date: budget.start_date, end_date: budget.end_date, total_order_amount: total_order_amount, budget_total_amount: budget_total_amount, difference_amount: diffrence_amount, status: status }
    end

    data
  end

  def budget_data_according_to_date(orders, start_date, end_date, branch_id, area)
    data = []
    budgetes = Budget.where("branch_id = ? and (DATE(start_date) >= (?) or DATE(end_date) <= ?)", branch_id, start_date, end_date)

    budgetes.each do |budget|
      orders = Order.where("branch_id = ? and DATE(created_at) >= (?) and DATE(created_at)  <= (?) and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branch_id, budget.start_date, budget.end_date, true, true, true, true, false, true)
      orders = orders.where(area: area) if area.present?
      total_order_amount = orders.pluck(:total_amount).sum
      budget_total_amount = budget.amount
      diffrence_amount = total_order_amount - budget_total_amount
      status = diffrence_amount > 0 ? "Profit" : "loss"
      address = budget.branch.address
      data << { address: address, order_count: orders.count, start_date: budget.start_date, end_date: budget.end_date, total_order_amount: total_order_amount, budget_total_amount: budget_total_amount, diffrence_amount: diffrence_amount, status: status }
    end

    data
  end

  def budget_over_all_data(branches, orders, area)
    data = []
    budgetes = Budget.where("branch_id IN (?)", branches.pluck(:id))

    budgetes.each do |budget|
      branches.each do |branch|
        orders = Order.where("branch_id = ? and DATE(created_at) >= (?) and DATE(created_at)  <= (?)and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branch.id, budget.start_date, budget.end_date, true, true, true, true, false, true)
        orders = orders.where(area: area) if area.present?
        total_order_amount = orders.pluck(:total_amount).sum
        budget_total_amount = budget.amount
        diffrence_amount = total_order_amount - budget_total_amount
        status = diffrence_amount > 0 ? "Profit" : "loss"
        address = orders.present? ? orders.last.branch.address : branch.address
        data << { address: address, order_count: orders.count, start_date: budget.start_date, end_date: budget.end_date, total_order_amount: total_order_amount, budget_total_amount: budget_total_amount, diffrence_amount: diffrence_amount, status: status }
      end
    end

    data
  end

  def budget_over_all_date_wise(start_date, end_date, branches, orders, area)
    data = []
    budgetes = Budget.where("branch_id IN (?)and (DATE(start_date) >= (?) and DATE(end_date) <= ?)", branches.pluck(:id), start_date, end_date)

    budgetes.each do |budget|
      branches.each do |branch|
        orders = Order.where("branch_id = ? and DATE(created_at) >= (?) and DATE(created_at)  <= (?)and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branch.id, budget.start_date, budget.end_date, true, true, true, true, false, true)
        orders = orders.where(area: area) if area.present?
        total_order_amount = orders.pluck(:total_amount).sum
        budget_total_amount = budget.amount
        diffrence_amount = total_order_amount - budget_total_amount
        status = diffrence_amount > 0 ? "Profit" : "loss"
        address = orders.present? ? orders.last.branch.address : branch.address
        data << { address: address, order_count: orders.count, start_date: budget.start_date, end_date: budget.end_date, total_order_amount: total_order_amount, budget_total_amount: budget_total_amount, diffrence_amount: diffrence_amount, status: status }
      end
    end

    data
  end

  def admin_get_top_customer_reports(branches, branch_id, start_date, end_date, area)
    customers = User.joins(:auths, :orders).where(auths: { role: "customer" }, orders: { dine_in: false, is_settled: true, branch_id: (branch_id.presence || branches.pluck(:id)) })
    customers = customers.where(orders: { area: area }) if area.present?
    customers = customers.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
    customers = customers.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
    customers = customers.group("orders.user_id").order("count(orders.user_id) DESC, users.name")
    result = customers.count.first(20).to_h
    result
  end

  def get_top_customer_reports(branches, branch_id, start_date, end_date, area)
    customers = User.joins(:auths, :orders).where(auths: { role: "customer" }, orders: { branch_id: (branch_id.presence || branches.pluck(:id)) })
    customers = customers.where(orders: { area: area }) if area.present?
    customers = customers.where("DATE(orders.created_at) >= ?", start_date) if start_date.present?
    customers = customers.where("DATE(orders.created_at) <= ?", end_date) if end_date.present?
    customers = customers.group("orders.user_id").order("count(orders.user_id) DESC")
    customers.count
  end

  def revenue_lost_reports(branches, branch, start_date, end_date, area)
    branch = branch.presence || branches.first.id
    orders = get_current_month_orders(branch, start_date, end_date, area)
    data = get_time_stamp_between_stages(orders)
  end

  def get_time_stamp_between_stages(orders)
    begin
      data = []
      stage12 = 0
      stage23 = 0
      stage34 = 0
      stage45 = 0
      stage56 = 0
      avstage12 = 0
      avstage23 = 0
      avstage34 = 0
      avstage45 = 0
      avstage56 = 0
      orders.each do |order|
        stage_1 = (order.accepted_at - order.created_at) / 60
        stage12 += stage_1.to_i
        stage_2 = (order.cooked_at - order.accepted_at) / 60
        stage23 += stage_2.to_i
        stage_3 = (order.pickedup_at - order.cooked_at) / 60
        stage34 += stage_3.to_i
        stage_4 = (order.delivered_at - order.pickedup_at) / 60
        stage45 += stage_4.to_i
        stage_5 = (order.settled_at - order.delivered_at) / 60
        stage56 += stage_5.to_i
        data << { id: order.id, stage1: stage_1.to_i, stage2: stage_2.to_i, stage3: stage_3.to_i, stage4: stage_4.to_i, stage5: stage_5.to_i }
      end
      data << { id: "Total", stage1: stage12, stage2: stage23, stage3: stage34, stage4: stage45, stage5: stage56 }
      data << { id: "Average", stage1: orders.present? ? stage12 / orders.count : 0, stage2: orders.present? ? stage23 / orders.count : 0, stage3: orders.present? ? stage34 / orders.count : 0, stage4: orders.present? ? stage45 / orders.count : 0, stage5: orders.present? ? stage56 / orders.count : 0 }
      data
    rescue Exception => e
      data << { id: "0", stage1: 0, stage2: 0, stage3: 0, stage4: 0, stage5: 0 }
    end
  end
end
