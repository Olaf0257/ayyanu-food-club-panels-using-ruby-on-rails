class EmailOnDeliveryCompanyDetailsUpdate
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(old_email, name, new_email)
    DeliveryCompanyMailer.delivery_company_details_update_mailer(old_email, name, new_email).deliver_now
  end
end
