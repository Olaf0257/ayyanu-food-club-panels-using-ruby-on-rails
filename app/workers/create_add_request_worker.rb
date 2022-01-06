class CreateAddRequestWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  sidekiq_options retry: false

  def perform(request_id)
    OfferMailer.create_add_request_mail(request_id).deliver_now
  end
end