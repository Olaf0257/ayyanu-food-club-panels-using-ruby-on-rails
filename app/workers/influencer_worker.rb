class InfluencerWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(email, name, data)
    UserMailer.send_approve_email(email, name, data).deliver_now
  end
end