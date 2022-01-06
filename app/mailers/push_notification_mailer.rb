class PushNotificationMailer < ApplicationMailer

  def push_notification_send_mail(recipent, title, description)
    @user = recipent
    @title = title
    @description = description
    mail(to: @user.email, subject: "Food Club")
  end
end
