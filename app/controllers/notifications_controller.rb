class NotificationsController < ApplicationController
  before_action :require_admin_logged_in

  def notification_list
    @notifications = get_all_notification(params[:status])
    if @admin.class.name =='SuperAdmin'
      @order_accepted = Notification.where("notification_type=?", "order_accept").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
      @order_rejected = Notification.where("notification_type=?", "order_reject").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
      @order_delivered = Notification.where("notification_type=?", "order_delivered").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      @order_accepted = Notification.includes(:restaurant).where(restaurants: { country_id: country_id }).where("notification_type=?", "order_accept").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
      @order_rejected = Notification.includes(:restaurant).where(restaurants: { country_id: country_id }).where("notification_type=?", "order_reject").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
      @order_delivered = Notification.includes(:restaurant).where(restaurants: { country_id: country_id }).where("notification_type=?", "order_delivered").paginate(page: params[:page], per_page: params[:per_page].presence || 20)
    end
    render layout: "admin_application"
  end

  def admin_notifications
    @notifications = Notification.all.order(updated_at: "DESC").paginate(page: params[:page], per_page: params[:per_page].presence || 20) # ,"business_create_booking","booking_complete_by_business"
    render layout: "partner_application"
   end

  def admin_notification_count
    userId = SuperAdmin.first.id
    u = Notification.all
    @unseen = Notification.where("admin_id = ? and seen_by_admin = ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ?", userId, false, "order_accept", "order_reject", "transporter_assigned", "order_delivered", "transporter_remove", "menu_category", "menu_item", "addon_item", "addon_category").count
    send_json_response("Notification list", "success", notifications: @unseen)
   end

  def update_notification
    result = update_notification_status
    respond_to do |format|
      format.js { render "admin_notifications_lists" }
    end
     # send_json_response("Notification Updated","upadted",{:notifications=>true})
   end

  def bulk_notification
    render layout: "admin_application"
   end

  def club_bulk_notification
    render layout: "admin_application"
   end

  def send_bulk_notifications
    if params[:title].present? && params[:description].present? && params[:filter_by].present?
      fire_notifications(params[:title], params[:description], params[:image], params[:filter_by])
      EmailOnPushNotification.perform_async(params[:filter_by], params[:title], params[:description])
      flash[:notice] = "Notifications sending has been started!"
    else
      if params[:email].present?
        result = fire_single_notification(params[:title], params[:description], params[:image], params[:email])
        if result
          EmailOnPushNotification.perform_async(params[:email], params[:title], params[:description])
          flash[:notice] = "Notifications sending has been started!"
        else
          flash[:error] = "email not exists!"
        end
      else
        flash[:error] = "Title, description must be present!"
      end
    end
    redirect_back(fallback_location: bulk_notification_path)
 end

  def send_club_user_bulk_notification
    begin
      if params[:title].present? && params[:description].present?
        if params[:category_type] == "club"
          club = get_club_details(params[:category_id])
          @users = club_user(club.id)
          send_club_user_notification(@users, params[:title], params[:description])
          flash[:notice] = "Notifications sending has been started!"
        end
      end
      rescue Exception => e
      flash[:notice] = "Notifications sending has been started!"
    end
    redirect_back(fallback_location: club_bulk_notification_path)
  end
end
