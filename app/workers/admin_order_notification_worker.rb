class AdminOrderNotificationWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  include RestaurantsHelper
  sidekiq_options retry: false

  def perform(id)
    order = Order.find_by(id: id)

    if order && order.is_accepted == false && order.is_rejected == false && order.is_cancelled == false
      send_notification_releted_menu("Order Id #{order.id} is Pending Approval for over 10 minutes for #{ order.branch.restaurant.title } (#{ order.branch.address })", "order_pending", order.user, SuperAdmin.first, order.branch.restaurant_id)
      OrderMailer.admin_pending_order_mail(order).deliver_now
    end
  end
end