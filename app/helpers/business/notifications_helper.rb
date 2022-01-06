module Business::NotificationsHelper
  def business_unseen_notifications
    unseen_count = Notification.where("receiver_id = ?", @user.id).order(created_at: "DESC").paginate(page: 1, per_page: 15) if @user.present?
    end

  def update_business_notification_status(userId)
    @unseen = Notification.where("receiver_id = ? and status = ?", userId, false)
    result = @unseen.update_all(status: true)
   end
end
