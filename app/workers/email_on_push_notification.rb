class EmailOnPushNotification
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(recipent, title, description)
    if %w[all_user all_Business all_customer all_influencer].include?(recipent)
      recipents = case recipent
                  when "all_user" then User.non_influencer_users.joins(:auths).where(auths: { role: %w[customer business] }).distinct
                  when "all_Business" then User.joins(:auths).where(auths: { role: "business" }).distinct
                  when "all_customer" then User.non_influencer_users.joins(:auths).where(auths: { role: "customer" }).distinct
                  when "all_influencer" then User.influencer_users.where(is_approved: 1)
                  else
                    []
                  end

      recipents.each do |recipent|
        PushNotificationMailer.push_notification_send_mail(recipent, title, description).deliver_now
      end
    else
      recipent = User.find_by(email: recipent)
      PushNotificationMailer.push_notification_send_mail(recipent, title, description).deliver_now
    end
  end
end
