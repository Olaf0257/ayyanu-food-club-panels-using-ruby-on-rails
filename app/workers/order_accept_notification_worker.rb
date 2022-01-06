class OrderAcceptNotificationWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  sidekiq_options retry: false

  def perform(id)
    order = Order.find_by(id: id)

    if order && order.is_cancelled == false && order.driver_assigned_at.present? && order.driver_accepted_at.nil? && order.transporter&.delivery_company_id.present?
      company_owner = User.joins(:auths).where(delivery_company_id: order.transporter.delivery_company_id, auths: { role: "delivery_company" }).first

      if company_owner.present?
        msg = "Order Id #{order.id} is Pending to be Accepted by Driver"
        send_pending_order_notification_to_delivery_company(get_admin_user, company_owner, "order_pending", msg)
        OrderMailer.driver_pending_order_mail(order, company_owner.email).deliver_now

        send_pending_order_notification_to_admin(msg, "driver_order_pending", order.transporter, get_admin_user, company_owner.delivery_company_id)
        OrderMailer.admin_driver_pending_order_mail(order).deliver_now
      end
    end
  end
end