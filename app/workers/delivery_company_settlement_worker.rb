class DeliveryCompanySettlementWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(recipent, action, reason, msg)
    recipent = User.find_by(email: recipent)
    DeliveryCompanyMailer.delivery_company_settle_amount_mailer(recipent, action, reason, msg).deliver_now
  end
end
