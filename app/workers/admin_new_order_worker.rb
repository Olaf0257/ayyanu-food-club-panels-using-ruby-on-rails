class AdminNewOrderWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include Api::V1::OrdersHelper
  include RestaurantsHelper
  sidekiq_options retry: false

  def perform(id)
    order = Order.find_by(id: id)
    OrderMailer.admin_new_order_mail(order).deliver_now
  end
end