class Business::SpotChecks::CashSpotChecksController < ApplicationController
  before_action :authenticate_business
  layout "partner_application"

  def index
    @cash_types = CashType.all
    user_ids = find_employees(params)
    @employees =  User.where(id: user_ids.flatten, approval_status: User::APPROVAL_STATUS[:approved]).order("created_at desc")
    render layout: "partner_application"
  end
end
