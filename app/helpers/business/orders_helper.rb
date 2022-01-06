module Business::OrdersHelper
  def get_partners_order_list(branch, keyword)
    orders = case keyword
             when "today"
               today_orders.where(branch_id: branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
             when "completed"
               completed_orders.where(branch_id: branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
             else
               order_by_branch(branch).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
             end
  end

  def today_orders
    Order.where("DATE(created_at) = (?)", Date.today)
  end

  def completed_orders
    Order.where(is_rejected: false, is_accepted: true, is_delivered: true, is_paid: true)
  end

  def find_order_orderd_items(order)
    OrderItem.find_order_items(order)
  end

  def send_notification_to_delivery_company(user, driver_id, order)
    delivery_company_owner_id = User.find(driver_id).delivery_company.users.joins(:auths).where(auths: { role: "delivery_company" }).first.id
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    channel_name = "delivery-company" + delivery_company_owner_id.to_s
    pusher_client.trigger(channel_name, "my-event", { root: channel_name, data: "test" })

    Notification.create(notification_type: "transporter_assigned", message: "Order assigned to Food Club Driver. Please re-assign", user_id: user.id, receiver_id: delivery_company_owner_id, order_id: order.id)
    rescue StandardError
  end

  def send_amount_settle_notification_to_delivery_company(admin, company, notification_type, msg)
    delivery_company_owner_id = company.users.joins(:auths).where(auths: { role: "delivery_company" }).first.id
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    channel_name = "delivery-company" + delivery_company_owner_id.to_s
    pusher_client.trigger(channel_name, "my-event", { root: channel_name, data: "test" })
    Notification.create(notification_type: notification_type, message: msg, admin_id: admin.id, receiver_id: delivery_company_owner_id)
    rescue StandardError
  end

  def send_pending_order_notification_to_delivery_company(admin, company_owner, notification_type, msg)
    @webPusher = web_pusher(Rails.env)

    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    channel_name = "delivery-company" + company_owner.id.to_s
    pusher_client.trigger(channel_name, "my-event", { root: channel_name, data: "test" })
    Notification.create(notification_type: notification_type, message: msg, admin_id: admin.id, receiver_id: company_owner.id)
    rescue StandardError
  end

  def send_amount_settle_notification_to_business(admin, branch_id, type, msg)
    restaurant = Branch.find(branch_id).restaurant

    @webPusher = web_pusher(Rails.env)
    pusher_client = Pusher::Client.new(
      app_id: @webPusher[:app_id],
      key: @webPusher[:key],
      secret: @webPusher[:secret],
      cluster: "ap2",
      encrypted: true
    )

    channelName = "public-branch" + branch_id.to_s # for branch managers
    pusher_client.trigger(channelName, "my-event", root: channelName)

    channelName = "public-restaurant" + restaurant.user.id.to_s # for restaurant owner
    pusher_client.trigger(channelName, "my-event", root: channelName, restaurant_id: encode_token(restaurant.id))

    noti = Notification.create(message: msg, notification_type: type, receiver_id: restaurant.user.id, admin_id: admin.id, menu_status: "Approved")
    rescue StandardError
  end

  def filter_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, order_type)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.delivery_orders.where(third_party_delivery: false)

    if branch.present? && keyword.present?
      orders = orders.joins(:user).where("branch_id = (?) and (name like (?) or orders.id = (?) or orders.contact = (?)) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch.id, "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, true, false, true, true, true, true)
    elsif branch.present?
      orders = orders.joins(:user).where("branch_id = (?) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch.id, true, false, true, true, true, true)
    elsif keyword.present?
      orders = orders.joins(:user, :branch).where("(name LIKE (?) or orders.id = ? or orders.contact = ?) and branch_id IN (?) and is_settled = (?) ", "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, brancheId, true)
    else
      orders = orders.joins(branch: :restaurant).where("branches.id in (?) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", brancheId, true, false, true, true, true, true)
    end

    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: order_type) if order_type.present?
    orders.order_by_date_desc
  end

  def filter_cancel_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, order_type)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.delivery_orders.where(third_party_delivery: false)

    if branch.present? && keyword.present?
      orders = orders.joins(:user).where("(name like (?) or orders.id = (?) or orders.contact = (?)) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, false, true, false, false, false, false, branch.id)
    elsif branch.present?
      orders = orders.joins(:user).where("branch_id = (?) and orders.is_rejected = (?)", branch.id, true)
    elsif keyword.present?
      orders = orders.joins(:user, :branch).where("(name LIKE (?) or orders.id = ? or orders.contact = ?) and branch_id IN (?) and orders.is_rejected = (?)", "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, brancheId, true)
    else
      orders = orders.joins(branch: :restaurant).where("branches.id in (?) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", brancheId, false, true, false, false, false, false)
    end

    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: order_type) if order_type.present?
    orders.order_by_date_desc
  end

  def filter_admin_cancel_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, order_type)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.delivery_orders.where(third_party_delivery: false)

    if branch.present? && keyword.present?
      orders = orders.joins(:user).where("(name like (?) or orders.id = ? or orders.contact = (?)) and orders.is_cancelled = ? and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, true, branch.id)
    elsif branch.present?
      orders = orders.joins(:user).where("branch_id = (?) and orders.is_cancelled = (?)", branch.id, true)
    elsif keyword.present?
      orders = orders.joins(:user, :branch).where("(name LIKE (?) or orders.id = ? or orders.contact = ?) and branch_id IN (?) and orders.is_cancelled = (?)", "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, brancheId, true)
    else
      orders = orders.joins(branch: :restaurant).where("branches.id in (?) and orders.is_cancelled = (?)", brancheId, true)
    end

    orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false })
    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: order_type) if order_type.present?
    orders.order_by_date_desc
  end

  def filter_dine_in_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, status, order_type, payment_type)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.dine_in_orders

    if branch.present? && keyword.present?
      orders = orders.where(id: keyword, branch_id: branch.id)
    elsif branch.present?
      orders = orders.where(branch_id: branch.id)
    elsif keyword.present?
      orders = orders.where(id: keyword, branch_id: brancheId)
    else
      orders = orders.where(branch_id: brancheId)
    end

    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: payment_type) if payment_type.present?

    if order_type == "Dine In"
      orders = orders.where.not(table_number: nil)
    elsif order_type == "Takeaway"
      orders = orders.where(table_number: nil)
    end

    if status.present?
      orders = orders.select { |o| o.current_status == status }
      orders = Order.where(id: orders.map(&:id))
    end

    orders.order_by_date_desc
  end

  def filter_foodclub_delivery_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, order_type, order_status)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.delivery_orders.where(third_party_delivery: true, is_cancelled: false).joins(:user)

    if branch.present? && keyword.present?
      orders = orders.where("branch_id = (?) and (name like (?) or orders.id = (?) or orders.contact = (?))", branch.id, "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword)
    elsif branch.present?
      orders = orders.where(branch_id: branch.id)
    elsif keyword.present?
      orders = orders.joins(:branch).where("(name LIKE (?) or orders.id = ? or orders.contact = ?) and branch_id IN (?)", "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, brancheId)
    else
      orders = orders.joins(branch: :restaurant).where("branches.id in (?)", brancheId)
    end

    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: order_type) if order_type.present?

    if order_status.present?
      filtered_orders = orders.select { |o| o.current_status == order_status }
      orders = Order.where(id: filtered_orders.map(&:id))
    end

    orders.order_by_date_desc
  end

  def filter_foodclub_delivery_cancelled_orders_data(user, restaurant, branch, keyword, area, start_date, end_date, order_type)
    restaurantId = restaurant.id

    if user.auth_role == "manager"
      brancheId = Branch.where(id: user.branch_managers.pluck(:branch_id)).is_subscribed.pluck(:id)
    else
      brancheId = restaurant.branches.is_subscribed.pluck(:id)
    end

    orders = Order.delivery_orders.where(third_party_delivery: true, is_cancelled: true).joins(:user)

    if branch.present? && keyword.present?
      orders = orders.where("branch_id = (?) and (name like (?) or orders.id = (?) or orders.contact = (?))", branch.id, "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword)
    elsif branch.present?
      orders = orders.where(branch_id: branch.id)
    elsif keyword.present?
      orders = orders.joins(:branch).where("(name LIKE (?) or orders.id = ? or orders.contact = ?) and branch_id IN (?)", "%#{keyword}%", keyword, keyword.length <= 8 ? "973" + "" + keyword : keyword, brancheId)
    else
      orders = orders.joins(branch: :restaurant).where("branches.id in (?)", brancheId)
    end

    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(order_type: order_type) if order_type.present?
    orders.order_by_date_desc
  end

  def filter_foodclub_delivery_orders_branch_wise(_user, branch, keyword, _status, _payment_mode)
    third_party_driver_ids = User.joins(:auths, :delivery_company).where(auths: { role: "transporter" }, delivery_companies: { country_id: branch.restaurant.country_id }).where.not(delivery_company_id: nil).pluck(:id)
    orders = Order.where(transporter_id: third_party_driver_ids).where(is_accepted: true, is_rejected: false, is_ready: true, pickedup: true, is_delivered: true, is_settled: false).joins(:user)

    if branch.present? && keyword.present?
      orders = orders.where("(name like (?) or orders.contact = (?) or orders.id = (?)) and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, branch.id)
    elsif branch.present?
      orders = orders.where(branch_id: branch.id)
    elsif keyword.present?
      orders = orders.joins(:branch).where("(name LIKE (?) or orders.id = ? or users.contact = ?) and branch_id = (?)", "%#{keyword}%", keyword, keyword, branch.id)
    else
      orders = orders.where(branch_id: branch.id)
    end

    orders.order_by_date_desc.paginate(page: params[:page], per_page: params[:per_page]).includes(:branch, :user)
  end

  def filter_foodclub_delivery_cancelled_orders_branch_wise(_user, branch, keyword, _status, _payment_mode)
    third_party_driver_ids = User.joins(:auths, :delivery_company).where(auths: { role: "transporter" }, delivery_companies: { country_id: branch.restaurant.country_id }).where.not(delivery_company_id: nil).pluck(:id)
    orders = Order.where(transporter_id: third_party_driver_ids, is_cancelled: true).joins(:user)

    if branch.present? && keyword.present?
      orders = orders.where("(name like (?) or orders.contact = (?) or orders.id = (?)) and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, branch.id)
    elsif branch.present?
      orders = orders.where(branch_id: branch.id)
    elsif keyword.present?
      orders = orders.joins(:branch).where("(name LIKE (?) or orders.id = ? or users.contact = ?) and branch_id = (?)", "%#{keyword}%", keyword, keyword, branch.id)
    else
      orders = orders.where(branch_id: branch.id)
    end

    orders.order_by_date_desc.paginate(page: params[:page], per_page: params[:per_page]).includes(:branch, :user)
  end

  def filter_foodclub_delivery_settle_amount_data(branch_ids, date)
    restaurant = Branch.find(branch_ids.first).restaurant
    third_party_driver_ids = User.joins(:auths, :delivery_company).where(auths: { role: "transporter" }, delivery_companies: { country_id: restaurant.country_id }).where.not(delivery_company_id: nil).pluck(:id)
    orders = Order.joins(:user).includes(:branch, :user).filter_by_date(date).where(transporter_id: third_party_driver_ids, branch_id: branch_ids, is_accepted: true, is_rejected: false, is_settled: false).pending_settled_orders.where.not(payment_approved_at: nil).order_by_date_desc
  end

  def restaurant_settle_amount_data(branch_ids, start_date, end_date, type, status)
    restaurant = Branch.find(branch_ids.first).restaurant
    third_party_driver_ids = User.joins(:auths, :delivery_company).where(auths: { role: "transporter" }, delivery_companies: { country_id: restaurant.country_id }).where.not(delivery_company_id: nil).pluck(:id)

    if type == "cash"
      orders = Order.joins(:user).includes(:branch, :user).where(transporter_id: third_party_driver_ids, branch_id: branch_ids, is_accepted: true, is_rejected: false).pending_settled_orders.where.not(payment_approved_at: nil).order_by_date_desc
    else
      orders = Order.joins(:user).includes(:branch, :user).where(branch_id: branch_ids, is_accepted: true, is_rejected: false).prepaid_settle_order_list(third_party_driver_ids)
    end

    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders = orders.where(paid_by_admin: (params[:status] == "Paid")) if status.present?
    orders
  end

  def restaurant_delivery_transaction_data(branch_ids, start_date, end_date, type, status)
    restaurant = Branch.find(branch_ids.first).restaurant
    orders = Order.joins(:user).includes(:branch, :user).where(third_party_delivery: false, branch_id: branch_ids, is_delivered: true)

    if type == "cash"
      orders = orders.cash_orders
    else
      orders = orders.online_orders
    end

    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders
  end

  def filter_cancel_orders_branch_wise(_user, branch, keyword, _status, _payment_mode)
    if branch.present? && keyword.present?
      orders = Order.joins(:user).where("(name like (?) or orders.contact = (?) or orders.id = (?)) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, false, true, false, false, false, false, branch.id).order("orders.id DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present?
      orders = Order.joins(:user).where("branch_id = (?) and orders.is_rejected = (?)", branch.id, true).order("orders.id DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif keyword.present?
      orders = Order.joins(:user, :branch).where("(name LIKE (?) or orders.id = ? or users.contact = ?) and branch_id = (?) and orders.is_rejected = (?)", "%#{keyword}%", keyword, keyword, branch.id, true).order("orders.id DESC").paginate(page: params[:page], per_page: params[:per_page])
    else
      orders = Order.joins(branch: :restaurant).where("branch_id = ? and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch.id, false, true, false, false, false, false).order("orders.id DESC").paginate(page: params[:page], per_page: params[:per_page])
    end
    orders.includes(:branch, :user)
  end

  def filter_admin_cancel_orders_branch_wise(_user, branch, keyword, _status, _payment_mode)
    third_party_driver_ids = User.joins(:auths, :delivery_company).where(auths: { role: "transporter" }, delivery_companies: { country_id: branch.restaurant.country_id }).where.not(delivery_company_id: nil).pluck(:id)
    orders = Order.includes(:iou).where("orders.transporter_id is null or orders.transporter_id not in (?)", third_party_driver_ids)

    if branch.present? && keyword.present?
      orders = orders.joins(:user).where("(name like (?) or orders.contact = (?) or orders.id = (?)) and orders.is_cancelled = ? and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, true, branch.id)
    elsif branch.present?
      orders = orders.joins(:user).where("branch_id = (?) and orders.is_cancelled = (?)", branch.id, true)
    elsif keyword.present?
      orders = orders.joins(:user, :branch).where("(name LIKE (?) or orders.id = ? or users.contact = ?) and branch_id = (?) and orders.is_cancelled = (?)", "%#{keyword}%", keyword, keyword, branch.id, true)
    else
      orders = orders.joins(branch: :restaurant).where("branch_id = ? and orders.is_cancelled", branch.id, true)
    end

    orders = Order.where(id: orders.reject { |o| o.iou&.is_received == false }).order("orders.id DESC").paginate(page: params[:page], per_page: params[:per_page])
    orders.includes(:branch, :user)
  end

  def order_by_branch(branch)
    Order.where(branch_id: branch.id).paginate(page: params[:page], per_page: params[:per_page])
  end

  def order_with_staus_accepted
    Order.where("is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?)", true, false, false, false)
  end

  def order_with_staus_rejected
    Order.where("is_rejected = (?) and is_accepted = (?)", true, false)
  end

  def order_with_staus_on_way
    Order.where("is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?)", true, false, true, true, false)
  end

  def order_with_staus_deliverd
    Order.where("is_accepted = (?) and is_rejected = (?) and is_ready = (?) and is_delivered = (?)", true, false, true, true)
  end

  def web_branch_transport(branch_id, restaurant, busy_transporter_ids)
    branch = @user&.auths&.first&.role == "business" ? restaurant.branches.find_by(id: branch_id) : @user&.branch_managers&.first&.branch
    branch = Branch.find_by(id: branch_id) unless branch.present?
    if branch
      transporters = busy_transporter_ids.present? ? branch.users.where(status: true).where.not(id: busy_transporter_ids) : find_branch_transporter(branch)
      transporters.as_json
      # else
      #   responce_json({:code=>422, :message=>"Branch not available!!"})
    end
  end

  def filter_orders_branch_wise(_user, branch, keyword, status, payment_mode)
    paymentMode = payment_mode == "online" ? "online" : "COD"
    if branch.present? && keyword.present? && status.present? && payment_mode.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user).where("branch_id = (?) and name LIKE (?) and payment_mode = (?) ", branch.id, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user).where("branch_id = (?) and name LIKE (?) and payment_mode = (?) ", branch.id, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user).where("branch_id = (?) and name LIKE (?) and payment_mode = (?) ", branch.id, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user).where("branch_id = (?) and name LIKE (?) and payment_mode = (?) ", branch.id, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif branch.present? && keyword.present? && status.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user).where("branch_id = (?) and name LIKE (?)", branch.id, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user).where("branch_id = (?) and name LIKE (?)", branch.id, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user).where("branch_id = (?) and name LIKE (?)", branch.id, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user).where("branch_id = (?) and name LIKE (?)", branch.id, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif branch.present? && keyword.present? && payment_mode.present?
      orders = Order.joins(:user).where("branch_id = (?) and payment_mode = (?) or name like (?) or orders.id = ? ", branch.id, paymentMode, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present? && status.present? && payment_mode.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user).where("payment_mode = (?) and branch_id = (?) ", paymentMode, branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user).where("payment_mode = (?) and branch_id = (?) ", paymentMode, branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user).where("payment_mode = (?) and branch_id = (?) ", paymentMode, branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user).where("payment_mode = (?) and branch_id = (?) ", paymentMode, branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif keyword.present? && status.present? && payment_mode.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif branch.present? && status.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user).where("branch_id = (?) ", branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user).where("branch_id = (?) ", branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user).where("branch_id = (?) ", branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user).where("branch_id = (?) ", branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif branch.present? && keyword.present?
      orders = Order.joins(:user).where("(name like (?) or orders.contact = (?) or orders.id = (?) ) and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?) and branch_id = (?)", "%#{keyword}%", keyword.length <= 8 ? "973" + "" + keyword : keyword, keyword, true, false, true, true, true, true, branch.id).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif branch.present? && payment_mode.present?
      orders = Order.joins(:user).where("branch_id = (?) and payment_mode = ?", branch.id, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif status.present? && payment_mode.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user, :branch).where("branches.restaurant_id = (?) and payment_mode = (?) ", restaurantId, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user, :branch).where("branches.restaurant_id = (?) and payment_mode = (?) ", restaurantId, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user, :branch).where("branches.restaurant_id = (?) and payment_mode = (?) ", restaurantId, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user, :branch).where("branches.restaurant_id = (?) and payment_mode = (?) ", restaurantId, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif keyword.present? && status.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user, :branch).where("branches.restaurant = (?) and name LIKE (?) or orders.id = (?)", restaurantId, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user, :branch).where("branches.restaurant = (?) and name LIKE (?) or orders.id = (?)", restaurantId, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user, :branch).where("branches.restaurant = (?) and name LIKE (?) or orders.id = (?)", restaurantId, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user, :branch).where("branches.restaurant = (?) and name LIKE (?) or orders.id = (?)", restaurantId, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif keyword.present? && payment_mode.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = (?) and payment_mode = (?) ", restaurantId, keyword, keyword, paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif branch.present?
      orders = Order.joins(:user).where("branch_id = ? and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch.id, true, false, true, true, true, true).order("id DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif keyword.present?
      orders = Order.joins(:user, :branch).where("branches.restaurant_id = (?) and name LIKE (?) or orders.id = ? ", restaurantId, keyword, keyword).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
    elsif status.present?
      if status == "accepted"
        orders = order_with_staus_accepted.joins(:branch).where("branches.restaurant_id = (?)", restaurantId).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "rejected"
        orders = order_with_staus_rejected.joins(:branch).where("branches.restaurant_id = (?)", restaurantId).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      elsif status == "onway"
        orders = order_with_staus_on_way.joins(:branch).where("branches.restaurant_id = (?)", restaurantId).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      else
        orders = order_with_staus_deliverd.joins(:branch).where("branches.restaurant_id = (?)", restaurantId).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
      end
    elsif payment_mode.present?
      orders = Order.joins(:user).where("payment_mode = ?", paymentMode).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page])
    else
      orders = Order.where("branch_id = ? and is_accepted = (?) and orders.is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch.id, true, false, true, true, true, true).order("id DESC").paginate(page: params[:page], per_page: params[:per_page])
    end
    orders.order(id: "DESC")
  end

  def get_restaurant_sales(branches_id)
    helpers.number_with_precision(Order.where("branch_id IN (?) and pickedup = ? and is_delivered = ? and is_ready = ? and is_accepted = ? and is_rejected = ?", branches_id, true, true, true, true, false).pluck(:total_amount).sum, precision: 3)
  end

  def get_branch_sales(branch_id)
    number_with_precision(Order.where("branch_id = (?) and pickedup = ? and is_delivered = ? and is_ready = ? and is_accepted = ? and is_rejected = ?", branch_id, true, true, true, true, false).pluck(:total_amount).sum, precision: 3)
  end

  def get_restaurant_ratings(branch_id, start_date, end_date)
    ratings = Rating.includes(:user, :branch, :order).where("branch_id IN (?) ", branch_id)
    ratings = ratings.where("DATE(ratings.created_at) >= ?", params[:start_date].to_date) if params[:start_date].present?
    ratings = ratings.where("DATE(ratings.created_at) <= ?", params[:end_date].to_date) if params[:end_date].present?
    ratings.order("created_at DESC")
  end

  def get_restaurant_order_reviews(restaurant_id, _page, per_page)
    perPage = per_page ? per_page : 20
    OrderReview.includes(:user, :restaurant, :order).where("restaurant_id = (?) ", restaurant_id).order("id DESC").paginate(page: params[:page], per_page: perPage)
  end

  def get_current_month_orders(branch, start_date, end_date, area)
    orders = Order.where("branch_id = ? and is_accepted = (?) and is_rejected = (?) and is_ready = (?) and pickedup = (?) and is_delivered = (?) and is_settled = (?)", branch, true, false, true, true, true, true)
    orders = orders.where(area: area) if area.present?
    orders = orders.where("DATE(orders.created_at) >= ?", start_date.to_date) if start_date.present?
    orders = orders.where("DATE(orders.created_at) <= ?", end_date.to_date) if end_date.present?
    orders  = orders.order("Id DESC")
  end
end
