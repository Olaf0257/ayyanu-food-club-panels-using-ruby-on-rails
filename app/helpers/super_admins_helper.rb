module SuperAdminsHelper
  def order_graph_data(keyword)
    result = []
    currentOfMonth = Date.current.beginning_of_month
    currentWeek = Date.current
    weekend = Date.current
    endOfMonth = currentOfMonth.end_of_month
    currentOf = Date.current.beginning_of_month
    endOfMonth = currentOfMonth.end_of_month
    currentOfMonth = Date.current.beginning_of_month
    endOfMonth = currentOfMonth.end_of_month
    orderAccept = Order.order_accept
    orderReject = Order.order_reject
    case keyword
    when "day"
      (0..23).each do |m|
        keyTime = (Time.zone.now - m.hours)

        data = {}
        data["key"] = (Time.zone.now - m.hours).strftime "%H"
        data["accept"] = day_orderData(keyTime - 1.hour, keyTime, orderAccept).count
        data["reject"] = day_orderData(keyTime - 1.hour, keyTime, orderReject).count
        result << data
        # p data
      end
    when "month"
      (0..29).each do |m|
        data = {}
        # byebug
        data["key"] = (currentWeek - m.day)
        data["accept"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderAccept).count
        data["reject"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderReject).count
        result << data
        # p data
      end
    when "week"
      (0..6).each do |m|
        data = {}
        # byebug
        data["key"] = (currentWeek - m).strftime("%A")
        data["accept"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderAccept).count
        data["reject"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderReject).count
        result << data
      end
    when "year"
      (0..11).each do |m|
        data = {}
        data["key"] = (currentOfMonth - m.months).strftime("%B")
        data["accept"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderAccept).count
        data["reject"] = orderData(currentOfMonth - m.months, endOfMonth - m.months, orderReject).count
        result << data
      end
    end

    result
  end

  def orderData(currentOfMonth, endOfMonth, orders)
    if @admin.class.name =='SuperAdmin'
    orders.where("DATE(created_at) >= ? and DATE(created_at) <= ?", currentOfMonth, endOfMonth)
  else
    country_id = @admin.class.find(@admin.id)[:country_id]
    orders.includes(branch: :restaurant).where(restaurants: { country_id: country_id }).where("DATE(orders.created_at) >= ? and DATE(orders.created_at) <= ?", currentOfMonth, endOfMonth)
  end
  end

  def day_orderData(privious, current_time, orders)
    if @admin.class.name == "SuperAdmin"
      orders.where("orders.created_at BETWEEN ? AND ?", privious, current_time)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      orders.includes(branch: :restaurant).where(restaurants: { country_id: country_id }).where("orders.created_at BETWEEN ? AND ?", privious, current_time)
    end
  end
end
