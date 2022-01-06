module UsersHelper
  def search_user_list(role, keyword, restaurant, country_id, state_id, delivery_company_id, restaurant_id, start_date, end_date)
    if keyword.present? && role.present?
      users = User.joins(:auths).where("auths.role = ? and (users.name like (?) or users.email = (?) or users.contact = ? or users.user_name like ?)", role, "%#{keyword}%", keyword.to_s, keyword, "%#{keyword}%").all
    elsif keyword.present?
      users = User.joins(:auths).where("auths.role = ? and (users.name like (?) or users.email = (?) or users.contact = ? or users.user_name like ?)", role, "%#{keyword}%", "%#{keyword}%", keyword, "%#{keyword}%")
    elsif restaurant.present?
      users = User.joins(:auths, orders: [:branch]).where("auths.role = ? and orders.branch_id IN (?) and (users.name like (?) or users.email = (?) or users.contact = ? or users.user_name like ?)", role, restaurant.branches.pluck(:id), "%#{keyword}%", "%#{keyword}%", keyword, "%#{keyword}%").distinct
    elsif role.present?
      users = User.joins(:auths).where("auths.role = (?)", role).distinct
    else
      users = User.joins(:auths, orders: [:branch]).where("auths.role = ?", role)
    end
    if restaurant.present?
      users = User.joins(:auths, orders: [:branch]).where("auths.role = ? and orders.branch_id IN (?) and (users.name like (?) or users.email = (?) or users.contact = ? or users.user_name like ?)", role, restaurant.branches.pluck(:id), "%#{keyword}%", "%#{keyword}%", keyword, "%#{keyword}%").distinct
    end
    users = users.where(country_id: @admin.country_id) if @admin.present? && @admin.class.name != "SuperAdmin"
    users = users.filter_by_country(country_id) if country_id.present?
    users = users.joins(:delivery_company).where(delivery_companies: { state_id: state_id }) if state_id.present?
    users = users.where(delivery_company_id: delivery_company_id) if delivery_company_id.present?
    users = users.joins(:branches).where(branches: { restaurant_id: restaurant_id }) if restaurant_id.present?
    users = users.where("DATE(users.created_at) >= ?", start_date.to_date) if start_date.present?
    users = users.where("DATE(users.created_at) <= ?", end_date.to_date) if end_date.present?
    users.distinct.reject_ghost_driver.order(id: "DESC").includes(:country, :addresses)
  end

  def resturant_search_user_list(role, keyword, restaurant, start_date, end_date)
    if keyword.present?
      users = User.joins(:auths).where("auths.role = ? and (users.name like (?) or users.email = (?) or users.contact = ? or users.user_name like ?)", role, "%#{keyword}%", keyword.to_s, keyword, "%#{keyword}%").all
    else
      users = User.joins(:auths).where("auths.role = ?", role)
    end
    users = users.where(restaurant_user_id: restaurant.id) if restaurant.present?
    users = users.where("DATE(users.created_at) >= ?", start_date.to_date) if start_date.present?
    users = users.where("DATE(users.created_at) <= ?", end_date.to_date) if end_date.present?
    users.distinct.reject_ghost_driver.order(id: "DESC").includes(:country, :addresses)
  end

  def get_user_transaction(restaurant, user)
    Point.joins(:branch, :user).where("user_id = ? and branch_id IN (?)", user.id, restaurant.branches.pluck(:id)).includes(:branch, :user).order(id: "DESC").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
  end

  def get_payment_data_restaurant_wise(keyword)
    allRestaurant = []

    if keyword.present?
      @rests = Restaurant.joins(:branches).where("title LIKE (?) and (is_subscribe = ? or branches.is_approved = ?)", "%#{keyword}%", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
    else
      @rests = Restaurant.joins(:branches).where("is_subscribe = ? or branches.is_approved=?", true, true).distinct.paginate(page: params[:page], per_page: params[:per_page])
    end

    allRestaurant
  end

  def prepaidTotalAmount(restId)
    total_amount = Order.joins(branch: :restaurant).where("order_type = ? and restaurant_id = ?", "prepaid", restId).pluck(:total_amount).sum
    number_with_precision(total_amount, precision: 3)
  end

  def send_email_on_approve_user(email, name, password)
    UserMailer.send_email_on_approve_user(email, name, password).deliver_now
  rescue Exception => e
  end

  def is_super_admin?(admin)
    admin.class.name == "SuperAdmin"
  end

  def is_call_center_executive?(admin)
    admin.class.name == "User" && admin.role&.role_name.to_s == "Call Center"
  end

  def create_influencer_user(user)
    password = SecureRandom.hex(5)
    Auth.create_user_password(user, password, "customer")
    InfluencerWorker.perform_async(user.email, user.name, password)
  end
end
