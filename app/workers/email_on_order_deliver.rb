class EmailOnOrderDeliver
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(order_id)
    order = Order.find_by(id: order_id)

    if order
      OrderMailer.order_deliver_mail(order).deliver_now
      OrderMailer.vat_order_deliver_mail(order).deliver_now unless order.third_party_delivery
    end
  end
end
