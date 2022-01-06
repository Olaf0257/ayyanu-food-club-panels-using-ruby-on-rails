class Business::NotificationsController < ApplicationController
  before_action :authenticate_business

  def business_notifications
    @restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if @restaurant
      @notifications = Notification.includes(:user).where(receiver_id: @user.id).order(updated_at: "DESC").paginate(page: params[:page], per_page: params[:per_page].presence || 20) # ,"business_create_booking","booking_complete_by_business"
      @notifications.update_all(status: true)
      render layout: "partner_application"
    else
      @notifications = Notification.includes(:user).where(receiver_id: @user.id).order(updated_at: "DESC").paginate(page: params[:page], per_page: params[:per_page].presence || 20) # ,"business_create_booking","booking_complete_by_business"
      render layout: "partner_application"
    end

    rescue Exception => e
  end

  def business_notification_count
    userId = @user.auths.first.role == "business" ? @user : @user.auths.first.role == "manager" ? (@user.branch_managers.present? ? @user.branch_managers.first.branch.restaurant.user : nil) : (@user.branch_kitchen_managers.present? ? @user.branch_kitchen_managers.first.branch.restaurant.user : nil)
    userId = @user if userId.nil? && @user.auth_role == "delivery_company"

    if userId
      u = Notification.includes(:order).where("receiver_id = ? and status = ?", userId.id, false)
      @unseen = Notification.includes(:order).where("receiver_id = ? and status = ?", userId.id, false)
      count = @unseen.count
      noti_data = @unseen
      order_last = @unseen.present? ? @unseen.last.order.present? ? @unseen.last.order.is_accepted : true : true
      is_pos_check = @unseen&.last&.order&.pos_check_id.present?
      status = order_last == false
    end

    send_json_response("Notification list", "success", notifications: count, status: status, noti_data: noti_data&.last, is_pos_check: is_pos_check)
  end

  def update_business_notification
    userId = @user.auths.first.role == "business" ? @user : @user.auths.first.role == "manager" ? @user.branch_managers.present? ? @user.branch_managers.first.branch.restaurant.user : @user.branch_kitchen_managers.present? ? @user.branch_kitchen_managers.first.branch.restaurant.user : nil : nil
    userId = @user if userId.nil? && @user.auth_role == "delivery_company"
    result = update_business_notification_status(userId)
    respond_to do |format|
      format.js { render "business_notifications_lists", locals: { restaurant_id: params[:restaurant_id] } }
    end
    end
end
