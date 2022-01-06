class DeliveryCompanyMailer < ApplicationMailer
  def send_reject_email(email, name, reason)
    @email = email
    @user_name = name
    @reason = reason
    mail(to: @email, subject: "Company Rejected by Food Club")
  end

  def send_approve_email(email, name, password)
    @email = email
    @user_name = name
    @password = password
    mail(to: @email, subject: "Company Approved by Food Club")
  end

  def delivery_company_details_update_mailer(old_email, name, new_email)
    email = old_email
    @name = name
    @new_email = new_email
    mail(to: email, subject: "Email Updated")
  end

  def delivery_company_settle_amount_mailer(recipent, action, reason, msg)
    @user = recipent
    @action = action
    @reason = reason
    @msg = msg
    mail(to: @user.email, subject: "Amount Settlement #{ action.to_s.titleize }")
  end
end
