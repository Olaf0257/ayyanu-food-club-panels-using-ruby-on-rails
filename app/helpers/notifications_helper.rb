module NotificationsHelper
  def admin_unseen_notifications
    unseen_count = Notification.where("notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ?", "order_accept", "order_reject", "transporter_assigned", "order_delivered", "transporter_remove", "order_onway", "menu_category", "menu_item", "addon_item", "addon_category").order(created_at: "DESC").paginate(page: 1, per_page: 15)
  end

  def update_notification_status
    @user = SuperAdmin.first
    @unseen = Notification.where("admin_id = ? and seen_by_admin = ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ? and notification_type != ?  and notification_type != ?  and notification_type != ?  and notification_type != ?  and notification_type != ? ", @user, false, "order_accept", "order_reject", "transporter_assigned", "order_delivered", "transporter_remove", "menu_category", "menu_item", "addon_item", "addon_category")
    result = @unseen.update_all(seen_by_admin: true)
  end

  private

  def fire_single_notification(title, description, _img, email)
    user = User.find_by(email: email)

    if user
      device = user.auths.first.server_sessions.last&.session_device

      if device.present?
        device_id = device.device_id
        notiType = "bulk_notification"
        device.device_type == "android" ? BulkNotificationAndroidWorker.perform_async(notiType, title, description, device_id) : BulkNotificationIosWorker.perform_async(notiType, title, description, [device_id])
      end

      true
    else
      false
    end

    rescue Exception => e
  end

  def fire_notifications(title, description, _img, filter_by)
    android_result = get_notification_devices(filter_by, "android")
    android_device_id = android_result[:devices]
    ios_result = get_notification_devices(filter_by, "ios")
    ios_device_id = ios_result[:devices]

    if android_device_id.present? || ios_device_id.present?
      notiType = "bulk_notification"
      ios_device_id.present? ? BulkNotificationIosWorker.perform_async(notiType, title, description, ios_device_id) : ""
      android_device_id.present? ? BulkNotificationAndroidWorker.perform_async(notiType, title, description, android_device_id) : ""
    end
  end

  def get_notification_devices(filter_by, device_type)
    devices = case filter_by
              when "all_user" then get_all_user_device.where(device_type: device_type, auths: { role: %w[customer business] }, users: { influencer: false }).where.not(device_id: nil).distinct
              when "all_Business" then get_all_user_device.where(device_type: device_type, auths: { role: "business" }).where.not(device_id: nil).distinct
              when "all_customer" then get_all_user_device.where(device_type: device_type, auths: { role: "customer" }, users: { influencer: false }).where.not(device_id: nil).distinct
              when "all_influencer" then get_all_user_device.where(device_type: device_type, auths: { role: "customer" }, users: { influencer: true, is_approved: 1 }).where.not(device_id: nil).distinct
              else
                []
              end

    device_ids = devices.pluck(:device_id).uniq
    result = { devices: device_ids }
    result
  end

  def get_all_user_device
    if @admin.class.name == "SuperAdmin"
      SessionDevice.joins(server_session: { auth: :user })
    else
      country_id = @admin.class.find(@admin.id)[:country_id]
      SessionDevice.joins(server_session: { auth: :user }).where(users: { country_id: country_id })
    end
  end

  def send_club_user_notification(users, title, description)
    android_result = get_club_notification_devices(users, "android")
    android_device_id = android_result[:devices]
    ios_result = get_club_notification_devices(users, "ios")
    ios_device_id = ios_result[:devices]
    if android_device_id.present? || ios_device_id.present?
      #   image = "https://res.cloudinary.com/dvs2kznsy/image/upload/v1522420454/notifications/email-icon-fb-size.png"
      #   if img.present?
      #     begin
      #       m = Cloudinary::Uploader.upload(img, :folder => "/notifications/")
      #       image = m["secure_url"]
      #     rescue Exception => e
      #     end
      #   end
      notiType = "bulk_notification"
      ios_device_id.present? ? BulkNotificationIosWorker.perform_async(notiType, title, description, android_device_id) : ""
      if android_device_id.present?
        android_device_id.present? ? BulkNotificationAndroidWorker.perform_async(notiType, title, description, android_device_id) : ""
      end
    end

    rescue Exception => e
  end

  def get_club_notification_devices(user, device_type)
    devices = get_all_user_device.where("device_type = ? and user_id IN (?)", device_type, user.pluck(:id)).where.not(device_id: nil) # .pluck(:device_id).uniq
    device_ids = devices.pluck(:device_id).uniq
    result = { devices: device_ids }
  end

  def get_all_notification(status)
    per_page = params[:per_page].presence || 20
    if @admin.class.name =='SuperAdmin'
    case status
    when "order_created"
      Notification.includes(:user, :order, :restaurant).where("notification_type = ?", "order_created").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_accept"
      Notification.includes(:user, :order, :restaurant).where("notification_type = ?", "order_accept").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_reject"
      Notification.includes(:user, :order, :restaurant).where("notification_type = ?", "order_reject").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_delivered"
      Notification.includes(:user, :order, :restaurant).where("notification_type = ?", "order_delivered").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "transporter_assigned"
      Notification.includes(:user, :order, :restaurant).where("notification_type = ?", "transporter_assigned").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    else
      Notification.includes(:user, :order, :restaurant).all.order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    end
  else
    country_id = @admin.class.find(@admin.id)[:country_id]
    case status
    when "order_created"
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).where("notification_type = ?", "order_created").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_accept"
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).where("notification_type = ?", "order_accept").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_reject"
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).where("notification_type = ?", "order_reject").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "order_delivered"
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).where("notification_type = ?", "order_delivered").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    when "transporter_assigned"
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).where("notification_type = ?", "transporter_assigned").order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    else
      Notification.includes(:user, :order, :restaurant).where(restaurants: { country_id: country_id }).all.order(id: "DESC").paginate(page: params[:page], per_page: per_page)
    end
  end
  end

end
