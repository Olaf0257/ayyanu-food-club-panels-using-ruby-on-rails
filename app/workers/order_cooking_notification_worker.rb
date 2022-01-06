class OrderCookingNotificationWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  sidekiq_options retry: false

  def perform(id, time)
    order = Order.find_by(id: id)

    if order && order.is_ready == false && order.is_cancelled == false
      Notification.create(notification_type: "late_order", message: "Late Order Id #{id}: #{time} mins", user_id: order.user&.id, receiver_id: order.branch.restaurant.user.id, order_id: order.id, menu_status: "Late Order")
      orderCookingPusherNotification(order.user, order)
      send_notification_releted_menu("Late Order Id #{id}: #{time} mins for #{ order.branch.restaurant.title } Restaurant", "late_order", order.user, SuperAdmin.first, order.branch.restaurant_id)
      OrderMailer.late_order_mail(order, time).deliver_now
      OrderMailer.admin_late_order_mail(order, time).deliver_now
    end
  end
end