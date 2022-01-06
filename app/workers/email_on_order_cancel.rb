class EmailOnOrderCancel
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(order_id)
    order = Order.find_by(id: order_id)
    OrderMailer.order_cancel_mail(order).deliver_now if order
    OrderMailer.admin_cancel_order_mail(order).deliver_now
  end
end
