class ManualOrderWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(name, email, password, restaurant)
    UserMailer.send_manual_order_mail(name, email, password, restaurant).deliver_now
  end
end