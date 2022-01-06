module Api::V1::NotificationsHelper
  def notification_json(notifications)
    notifications.as_json
  end

  def get_user_notification(user, page, per_page)
    Notification.find_user_notifications(user, page, per_page)
  end

  def get_notification(user, notification_id)
    Notification.find_notification(user, notification_id)
  end

  def get_unseen_notification(user)
    Notification.find_all_unseen_notification(user)
  end
end
