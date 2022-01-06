class Api::V1::NotificationsController < Api::ApiController
  before_action :authenticate_guest_access

  def notification_list
    notifications = get_user_notification(@user, params[:page], params[:per_page])
    responce_json(code: 200, message: "Notifications list.", notifications: notification_json(notifications))
  end

  def seen_notifiction
    notification = get_notification(@user, params[:notification_id])
    if notification
      notification.update(status: true)
      responce_json(code: 200, message: "Notifications seen.", status: notification.status)
    else
      responce_json(code: 404, message: "Notification not found")
    end
  end

  def unseen_notification_count
    notification = @user ? get_unseen_notification(@user) : ""
    cart = @user ? @user.cart : Cart.find_by(guest_token: @guestToken)
    cart_items_count = cart.present? ? cart.cart_items.present? ? cart.cart_items.pluck(:quantity).map(&:to_i).sum : 0 : 0
    responce_json(code: 200, notification_count: notification.present? ? notification.count : 0, cart_item_count: cart_items_count)
  end
end
