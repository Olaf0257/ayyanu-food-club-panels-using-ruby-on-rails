class Influencer::InfluencerUsersController < ApplicationController
  before_action :authenticate_business

  def dashboard
    @available_points = @user.total_available_points
    @referrals = @user.referrals.size

    respond_to do |format|
      format.html { render layout: "partner_application" }
      format.js { render "index" }
    end
  end

  def available_points
    @points = @user.points.order(created_at: :desc).paginate(page: params[:page], per_page: 50)
    @total_points = @user.total_available_points
    render layout: "partner_application"
  end

  def sold_points
    render layout: "partner_application"
  end

  def referrals
    @referrals = @user.referrals.order(created_at: :desc).paginate(page: params[:page], per_page: 50)
    render layout: "partner_application"
  end
end