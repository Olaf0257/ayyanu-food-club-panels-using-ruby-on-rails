class DeliveryCompanyWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(email, name, data, status)
    if status == "approved"
      DeliveryCompanyMailer.send_approve_email(email, name, data).deliver_now
    elsif status == "rejected"
      DeliveryCompanyMailer.send_reject_email(email, name, data).deliver_now
    end
  end
end