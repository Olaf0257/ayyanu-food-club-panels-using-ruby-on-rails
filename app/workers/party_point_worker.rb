class PartyPointWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id, restaurant_id)
    UserMailer.influencer_point_selling_email(user_id, restaurant_id).deliver_now
  end
end