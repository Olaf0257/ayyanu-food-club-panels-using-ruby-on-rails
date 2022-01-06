class EmailOnOrderReject
  include Sidekiq::Worker

  sidekiq_options retry: false
  def perform(order_id)
    order = Order.find_by(id: order_id)
    OrderMailer.order_reject_mail(order).deliver_now if order
  end
end
