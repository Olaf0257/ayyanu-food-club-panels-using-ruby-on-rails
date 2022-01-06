class EmailOrderPaymentLinkWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id, redeem, address_id, note)
    OrderMailer.payment_link_mail(user_id, redeem, address_id, note).deliver_now
  end
end