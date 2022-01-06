module ReportsHelper
  def get_top_selling_items(branch, all_branch)
    branch = branch.presence || all_branch.first.id
    orders = OrderItem.joins(:order, :menu_item).where("orders.branch_id = (?)", branch).group("menu_item_id").order("COUNT(menu_item_id) desc").count("menu_item_id")
    itemReportData = get_items_report(orders, branch)
    p itemReportData
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
      p percentage
      result << { id: menuItem.id, item_name: menuItem.item_name, item_rating: menuItem.item_rating, price_per_item: menuItem.price_per_item, totalItemCount: orderCount, percentage: helpers.number_with_precision(percentage, precision: 3) }
    end
    p result
    result
  end
end
