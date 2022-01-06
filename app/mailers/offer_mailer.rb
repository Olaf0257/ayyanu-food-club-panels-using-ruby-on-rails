class OfferMailer < ApplicationMailer
  def create_add_request_mail(request_id)
    @request = AddRequest.find(request_id)
    @user = @request.branch.restaurant.user
    @email = @user&.email
    mail(to: @email, subject: "Food Club Advertisement Request") if @email
  end

  def add_request_notification_mail(request_id)
    @request = AddRequest.find(request_id)
    @user = @request.branch.restaurant.user
    @email = @user&.email
    mail(to: @email, subject: "Food Club Advertisement Request Status") if @email
  end

  def advertisement_approval_mail(request_id)
    @request = AddRequest.find(request_id)
    @user = @request.branch.restaurant.user
    @email = @user&.email
    mail(to: @email, subject: "Food Club Advertisement Approved") if @email
  end
end