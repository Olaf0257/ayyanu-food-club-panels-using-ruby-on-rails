class OrderNotificationWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  sidekiq_options retry: false

  def perform(id)
    order = Order.find_by(id: id)

    if order && order.is_accepted == false && order.is_rejected == false && order.is_cancelled == false
      Notification.create(notification_type: "order_pending", message: "Order Id #{order.id} is Pending Approval.", user_id: order.user&.id, receiver_id: order.branch.restaurant.user.id, order_id: order.id)
      orderPusherNotification(order.user, order)
      OrderMailer.pending_order_mail(order).deliver_now

      if Rails.env.production?
        account_sid = Rails.application.secrets["twilio_account_sid"]
        auth_token = Rails.application.secrets["twilio_auth_token"]
        from = Rails.application.secrets["twilio_number"]
        to = order.branch.contact
        @client = Twilio::REST::Client.new(account_sid, auth_token)
        call = @client.calls.create(twiml: "<Response><Say>This Call is from Food Club. Order Number " + order.id.to_s + " is Pending Approval in your Panel. Please Accept the Order.</Say></Response>", to: to, from: from) if to.present?
      end
    end
  end
end