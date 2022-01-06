module WelcomeHelper
  def orders_graph_data(_user, branch_id)
    result = []
    currentMonth = Date.current.beginning_of_month
    endMonth = currentMonth.end_of_month
    (0...(currentMonth.strftime("%m").to_i)).each do |m|
      data = {}
      data["key"] = (currentMonth - m.months).strftime("%B")
      data["value"] = monthlyOrdersData(currentMonth - m.months, endMonth - m.months, branch_id).count
      result << data
    end
    result.reverse
  end

  def get_customer_data(_user, branch_id)
    result = []
    currentMonth = Date.current.beginning_of_month
    endMonth = currentMonth.end_of_month
    (0...(currentMonth.strftime("%m").to_i)).each do |m|
      data = {}
      branch = Branch.find_branch(branch_id.to_i)
      all_user = mobile_order_branch_wise(branch, currentMonth - m.months, endMonth - m.months).pluck(:user_id).uniq
      data["key"] = (currentMonth - m.months).strftime("%B")
      data["value"] = get_new_customer_order(branch, all_user).count
      result << data
    end
    result.reverse
  end

  def monthlyOrdersData(currentMonth, endMonth, branch_id)
    Order.where("DATE(created_at) >= ? and DATE(created_at) <= ? and branch_id=?", currentMonth, endMonth, branch_id)
  end

  def areas_graph_data(_user, branch_id)
    result = []
    branch = Branch.find_branch(branch_id.to_i)
    area_id = branch.coverage_areas.pluck(:coverage_area_id)
    coverage_areas = CoverageArea.get_coverage_areas(area_id)
    coverage_areas.each do |ar|
      data = {}
      orders = mobile_branches_all_order(branch).where("area = ?", ar.area)
      data["key"] = ar.area
      data["value"] = mobile_branches_all_order(branch).count > 0 ? (orders.count * 100) / mobile_branches_all_order(branch).count : "000"
      result << data
    end
    result
  end

  def mobile_order_branch_wise(branch, start_date, end_date)
    Order.where("DATE(created_at) >= ? and  DATE(created_at) <= ? and branch_id=?", start_date, end_date, branch.id)
  end

  def mobile_branches_all_order(branch)
    Order.includes(branch: :restaurant).where("branch_id = (?) and pickedup = ? and is_delivered =? and is_ready = ? and is_accepted = ? and is_rejected = ? and is_settled = ?", branch.id, true, true, true, true, false, true)
  end

  def menu_data_scraped
    data = params[:info][:content]
    data
  end
end
