module Business::PartnersHelper
  def business_day_earnings(keyword, _startdate, restaurant)
    restaurantId = restaurant.id
    currenttime = DateTime.now
    @dayresult = {}

    [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24].each do |h|
      keyTime = (currenttime - h.hours)
      case keyword
      when "income"
        totalorders =  Order.joins(:branch).where("orders.created_at BETWEEN ? AND ? and branches.restaurant_id = (?) ", (keyTime - 2.hours), keyTime, restaurantId).sum(:total_amount).to_f.round(3)
      when "orders"
        totalorders =  Order.joins(:branch).where("orders.created_at BETWEEN ? AND ? and is_rejected = (?) and branches.restaurant_id = (?) and is_cancelled = ?", (keyTime - 2.hours), keyTime, false, restaurantId, false).count
      end

      @dayresult[h.to_s] = totalorders
    end

    @dayresult
   end

  def business_week_earnings(keyword, startdate, restaurant)
    weekearnings = business_week_earnings_data(keyword, startdate, restaurant)
    @result = {}
    @result[startdate.strftime("%A").to_s] = weekearnings[0]
    @result[(startdate - 1.day).strftime("%A").to_s] = weekearnings[1]
    @result[(startdate - 2.days).strftime("%A").to_s] = weekearnings[2]
    @result[(startdate - 3.days).strftime("%A").to_s] = weekearnings[3]
    @result[(startdate - 4.days).strftime("%A").to_s] = weekearnings[4]
    @result[(startdate - 5.days).strftime("%A").to_s] = weekearnings[5]
    @result[(startdate - 6.days).strftime("%A").to_s] = weekearnings[6]
    @result
 end

  def business_week_earnings_data(keyword, startdate, restaurant)
    restaurantId = restaurant.id
    case keyword
    when "income"
      today = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?) ", startdate, restaurantId).sum(:total_amount)
      yesterday = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 1.day, restaurantId).sum(:total_amount)
      before3days = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 2.days, restaurantId).sum(:total_amount)
      before4days = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 3.days, restaurantId).sum(:total_amount)
      before5days = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 4.days, restaurantId).sum(:total_amount)
      before6days = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 5.days, restaurantId).sum(:total_amount)
      before7days = Order.joins(:branch).where("(DATE(orders.created_at))= ? and branches.restaurant_id = (?)", startdate - 6.days, restaurantId).sum(:total_amount)
    when "orders"
      today = Order.joins(:branch).where("DATE(orders.created_at)= ?   and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate, false, restaurantId, false).count
      yesterday = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 1.day, false, restaurantId, false).count
      before3days = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 2.days, false, restaurantId, false).count
      before4days = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 3.days, false, restaurantId, false).count
      before5days = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 4.days, false, restaurantId, false).count
      before6days = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 5.days, false, restaurantId, false).count
      before7days = Order.joins(:branch).where("DATE(orders.created_at)= ?  and is_rejected = ? and branches.restaurant_id = (?) is_cancelled = ?", startdate - 6.days, false, restaurantId, false).count
    end
    [format("%.3f", today), format("%.3f", yesterday), format("%.3f", before3days), format("%.3f", before4days), format("%.3f", before5days), format("%.3f", before6days), format("%.3f", before7days)]
  end

  def business_month_earnings(keyword, startdate, restaurant)
    restaurantId = restaurant.id
    today = keyword == "income" ? Order.joins(:branch).where("DATE(orders.created_at)= ? and branches.restaurant_id = (?)", startdate, restaurantId).sum(:total_amount) : Order.joins(:branch).where("DATE(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", startdate, false, restaurantId, false).count
    yesterday = keyword == "income" ? Order.joins(:branch).where("DATE(orders.created_at)= ? and branches.restaurant_id = (?)", startdate - 1.day, restaurantId).sum(:total_amount) : Order.joins(:branch).where("DATE(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", startdate - 1.day, false, restaurantId, false).count
    week1 = business_week_earnings_data(keyword, startdate - 2.days, restaurant)
    week2 = business_week_earnings_data(keyword, startdate - 9.days, restaurant)
    week3 = business_week_earnings_data(keyword, startdate - 16.days, restaurant)
    week4 = business_week_earnings_data(keyword, startdate - 23.days, restaurant)
    @result = {}
    [today, yesterday, week1, week2, week3, week4].flatten.each_with_index do |totalAmount, index|
      @result[(startdate - index.days).strftime("%Y-%m-%d").to_s] = format("%.3f", totalAmount)
    end
    @result
  end

  def business_year_earnings(keyword, startdate, restaurant)
    restaurantId = restaurant.id
    case keyword
    when "income"
      currentMonth = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", startdate.month, restaurantId).sum(:total_amount)
      before1month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 1.month).month, restaurantId).sum(:total_amount)
      before2month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 2.months).month, restaurantId).sum(:total_amount)
      before3month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 3.months).month, restaurantId).sum(:total_amount)
      before4month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 4.months).month, restaurantId).sum(:total_amount)
      before5month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 5.months).month, restaurantId).sum(:total_amount)
      before6month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 6.months).month, restaurantId).sum(:total_amount)
      before7month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 7.months).month, restaurantId).sum(:total_amount)
      before8month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 8.months).month, restaurantId).sum(:total_amount)
      before9month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 9.months).month, restaurantId).sum(:total_amount)
      before10month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 10.months).month, restaurantId).sum(:total_amount)
      before11month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and branches.restaurant_id = (?)", (startdate - 11.months).month, restaurantId).sum(:total_amount)
    when "orders"
      currentMonth = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", startdate.month, false, restaurantId, false).count
      before1month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 1.month).month, false, restaurantId, false).count
      before2month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 2.months).month, false, restaurantId, false).count
      before3month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and  = ?", (startdate - 3.months).month, false, restaurantId, false).count
      before4month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 4.months).month, false, restaurantId, false).count
      before5month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 5.months).month, false, restaurantId, false).count
      before6month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 6.months).month, false, restaurantId, false).count
      before7month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 7.months).month, false, restaurantId, false).count
      before8month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 8.months).month, false, restaurantId, false).count
      before9month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 9.months).month, false, restaurantId, false).count
      before10month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 10.months).month, false, restaurantId, false).count
      before11month = Order.joins(:branch).where("MONTH(orders.created_at)= ? and is_rejected = ? and branches.restaurant_id = (?) and is_cancelled = ?", (startdate - 11.months).month, false, restaurantId, false).count
     end
    @result = {}
    [currentMonth, before1month, before2month, before3month, before4month, before5month, before6month, before7month, before8month, before9month, before10month, before11month].each_with_index do |totalAmount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = format("%.3f", totalAmount)
    end
    @result
  end

  def get_manager_busy_restaurant_by_partner(branch_ids)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_busy = ? and branch_id in (?)", true, branch_ids)
  end

  def get_manager_branch_list(user)
    branches = BranchManager.where(user_id: user.id)
    Branch.where("id IN (?)", branches.pluck(:branch_id))
  end

  def get_manager_close_restaurant_by_partner(branch_ids)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_closed = ? and branch_id in (?)", true, branch_ids)
  end

  def get_business_busy_restaurant_by_business(restaurant_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_busy = ? and restaurant_id = ?", true, restaurant_id)
 end

  def get_business_close_restaurant_by_business(restaurant_id)
    BranchCoverageArea.joins(branch: :restaurant).where("branch_coverage_areas.is_closed = ? and restaurant_id = ?", true, restaurant_id)
  end

  def delivery_company_day_earnings(keyword, _startdate, company)
    company_id = company.id
    currenttime = DateTime.now
    @dayresult = {}

    [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24].each do |h|
      keyTime = (currenttime - h.hours)
      case keyword
      when "income"
        totalorders = Order.joins(:transporter).where("orders.created_at BETWEEN ? AND ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (keyTime - 2.hours), keyTime, company_id, false).sum(:total_amount).to_f.round(3)
      when "orders"
        totalorders = Order.joins(:transporter).where("orders.created_at BETWEEN ? AND ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (keyTime - 2.hours), keyTime, company_id, false).count
      end

      @dayresult[h.to_s] = totalorders
    end

    @dayresult
  end

  def delivery_company_week_earnings(keyword, startdate, company)
    weekearnings = delivery_company_week_earnings_data(keyword, startdate, company)
    @result = {}
    @result[startdate.strftime("%A").to_s] = weekearnings[0]
    @result[(startdate - 1.day).strftime("%A").to_s] = weekearnings[1]
    @result[(startdate - 2.days).strftime("%A").to_s] = weekearnings[2]
    @result[(startdate - 3.days).strftime("%A").to_s] = weekearnings[3]
    @result[(startdate - 4.days).strftime("%A").to_s] = weekearnings[4]
    @result[(startdate - 5.days).strftime("%A").to_s] = weekearnings[5]
    @result[(startdate - 6.days).strftime("%A").to_s] = weekearnings[6]
    @result
 end

  def delivery_company_week_earnings_data(keyword, startdate, company)
    company_id = company.id

    case keyword
    when "income"
      today = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate, company_id, false).sum(:total_amount)
      yesterday = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 1.day, company_id, false).sum(:total_amount)
      before3days = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 2.days, company_id, false).sum(:total_amount)
      before4days = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 3.days, company_id, false).sum(:total_amount)
      before5days = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 4.days, company_id, false).sum(:total_amount)
      before6days = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 5.days, company_id, false).sum(:total_amount)
      before7days = Order.joins(:transporter).where("(DATE(orders.created_at))= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 6.days, company_id, false).sum(:total_amount)
    when "orders"
      today = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate, company_id, false).count
      yesterday = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 1.day, company_id, false).count
      before3days = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 2.days, company_id, false).count
      before4days = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 3.days, company_id, false).count
      before5days = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 4.days, company_id, false).count
      before6days = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 5.days, company_id, false).count
      before7days = Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 6.days, company_id, false).count
    end

    [format("%.3f", today), format("%.3f", yesterday), format("%.3f", before3days), format("%.3f", before4days), format("%.3f", before5days), format("%.3f", before6days), format("%.3f", before7days)]
  end

  def delivery_company_month_earnings(keyword, startdate, company)
    company_id = company.id

    today = keyword == "income" ? Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate, company_id, false).sum(:total_amount) : Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate, company_id, false).count

    yesterday = keyword == "income" ? Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 1.day, company_id, false).sum(:total_amount) : Order.joins(:transporter).where("DATE(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate - 1.day, company_id, false).count

    week1 = delivery_company_week_earnings_data(keyword, startdate - 2.days, company)
    week2 = delivery_company_week_earnings_data(keyword, startdate - 9.days, company)
    week3 = delivery_company_week_earnings_data(keyword, startdate - 16.days, company)
    week4 = delivery_company_week_earnings_data(keyword, startdate - 23.days, company)
    @result = {}

    [today, yesterday, week1, week2, week3, week4].flatten.each_with_index do |totalAmount, index|
      @result[(startdate - index.days).strftime("%Y-%m-%d").to_s] = format("%.3f", totalAmount)
    end

    @result
  end

  def delivery_company_year_earnings(keyword, startdate, company)
    company_id = company.id

    case keyword
    when "income"
      currentMonth = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate.month, company_id, false).sum(:total_amount)
      before1month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 1.month).month, company_id, false).sum(:total_amount)
      before2month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 2.months).month, company_id, false).sum(:total_amount)
      before3month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 3.months).month, company_id, false).sum(:total_amount)
      before4month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 4.months).month, company_id, false).sum(:total_amount)
      before5month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 5.months).month, company_id, false).sum(:total_amount)
      before6month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 6.months).month, company_id, false).sum(:total_amount)
      before7month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 7.months).month, company_id, false).sum(:total_amount)
      before8month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 8.months).month, company_id, false).sum(:total_amount)
      before9month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 9.months).month, company_id, false).sum(:total_amount)
      before10month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 10.months).month, company_id, false).sum(:total_amount)
      before11month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 11.months).month, company_id, false).sum(:total_amount)
    when "orders"
      currentMonth = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", startdate.month, company_id, false).count
      before1month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 1.month).month, company_id, false).count
      before2month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 2.months).month, company_id, false).count
      before3month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 3.months).month, company_id, false).count
      before4month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 4.months).month, company_id, false).count
      before5month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 5.months).month, company_id, false).count
      before6month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 6.months).month, company_id, false).count
      before7month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 7.months).month, company_id, false).count
      before8month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 8.months).month, company_id, false).count
      before9month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 9.months).month, company_id, false).count
      before10month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 10.months).month, company_id, false).count
      before11month = Order.joins(:transporter).where("MONTH(orders.created_at)= ? and users.delivery_company_id = (?) and orders.is_cancelled = ?", (startdate - 11.months).month, company_id, false).count
     end

    @result = {}

    [currentMonth, before1month, before2month, before3month, before4month, before5month, before6month, before7month, before8month, before9month, before10month, before11month].each_with_index do |totalAmount, ind|
      @result[(startdate - ind.months).strftime("%B").to_s] = format("%.3f", totalAmount)
    end

    @result
  end
end
