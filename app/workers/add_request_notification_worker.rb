class AddRequestNotificationWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  sidekiq_options retry: false

  def perform(request_id)
    request = AddRequest.find(request_id)

    if AddRequest.where(place: "list", position: request.position, week_id: request.week_id, coverage_area_id: request.coverage_area_id).where("amount > ? OR (amount = ? AND id < ?)", request.amount, request.amount, request.id).present?
      OfferMailer.add_request_notification_mail(request_id).deliver_now
    end
  end
end