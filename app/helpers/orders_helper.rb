module OrdersHelper
  def get_all_orders(keyword, order_type, delivery_type, country_id, status, start_date, end_date)
    orders = Order.includes(:user, branch: :restaurant)
    orders = orders.where("DATE(orders.created_at) >= ? and DATE(orders.created_at) <= ?", (start_date.presence || Date.today).to_date, (end_date.presence || Date.today).to_date)
    orders = orders.joins(branch: :restaurant).where("orders.id = ? or branches.address like (?) or title LIKE (?)", keyword.to_s, "%#{keyword}%", "%#{keyword}%") if keyword.present?
    orders = orders.where(order_type: order_type) if order_type.present?
    orders = orders.where(third_party_delivery: (delivery_type == "true")) if delivery_type.present?
    orders = orders.where(restaurants: { country_id: @admin.country_id }) if @admin.class.name != "SuperAdmin"
    orders = orders.where(restaurants: { country_id: country_id }) if country_id.present?

    if status.present?
      orders = orders.select { |o| o.current_status == status }
      orders = Order.includes(:user, branch: :restaurant).where(id: orders.map(&:id))
    end

    orders = orders.order(id: "DESC")
  end

  def check_status(orders)
    if not_approved_orders = orders.select { |o| o.payment_approved_at == nil }
      if not_approved_orders.any? { |o| o.payment_approval_pending == false }
        return false
      else
        return true
      end
    else
      return true
    end
  end

  def event_calendar_order_date(dates)
    data = []

    dates.each do |event_date|
      if event_date.end_date.nil?
        orders = Order.where("DATE(created_at) = ? and is_delivered = true", event_date.start_date)
      else
        orders = Order.where("DATE(created_at) between ? AND ? and is_delivered = true", event_date.start_date, event_date.end_date)
      end

      data << { event_date_id: event_date.id, total_delivery_orders: orders.delivery_orders.size, total_delivery_order_amount: orders.delivery_orders.sum(:total_amount), total_dine_in_orders: orders.dine_in_orders.size, total_dine_in_order_amount: orders.dine_in_orders.sum(:total_amount), total_orders: orders.size, total_order_amount: orders.sum(:total_amount) }
    end

    data
  end
end
