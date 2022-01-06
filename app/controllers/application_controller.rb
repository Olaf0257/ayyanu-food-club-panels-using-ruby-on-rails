class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  before_action :set_cache_headers
  helper_method :current_user

  # skip_before_filter  :verify_authenticity_token
  include ApplicationHelper
  include Api::ApiHelper

  def current_user
    api_key = request.headers["HTTP_ACCESSTOKEN"].presence || session[:customer_user_id]
    server_session = ServerSession.where(server_token: api_key).first
    @server_session = server_session.server_token if server_session
    @current_user = server_session&.auth&.user
  end

  def find_employees(params)
    user_ids = []
    restaurant = get_restaurant_data(decode_token(params[:restaurant_id]))
    if restaurant && (@user.auths.first.role == "business")
      @branch = restaurant.branches.find_by(id: params[:branch])
      user_ids << filter_data(restaurant, @branch, params[:keyword], params[:vehicle_type]).map(&:id)
      user_ids << filter_managers(restaurant, @branch, params[:keyword]).includes(:manager_branches).distinct.map(&:id)
      user_ids << filter_kitchen_managers(restaurant, @branch, params[:keyword]).map(&:id)
    elsif @user.auths.first.role == "manager"
      @branch = @user.manager_branches.find_by(id: params[:branch])
      @restaurants = @user.restaurants
      user_ids << filter_data("", @branch, params[:keyword], params[:vehicle_type]).map(&:id)
      user_ids << filter_managers("", @branch, params[:keyword]).includes(:manager_branches).distinct.map(&:id)
      user_ids << filter_kitchen_managers("", @branch, params[:keyword]).map(&:id)
    end
    user_ids
  end

  private

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    session[:guest_token] ||= params[:guest_token] || SecureRandom.urlsafe_base64
  end

  def authenticate_business
    validRequest?
  end

  def authenticate_customer
    api_key = request.headers["HTTP_ACCESSTOKEN"].presence || session[:customer_user_id]
    server_session = ServerSession.where(server_token: api_key).first
    @server_session = server_session.server_token if server_session
    @user = server_session&.auth&.user
    @guestToken = session[:guest_token]

    if !api_key && !@user && !@guestToken
      redirect_to customer_customer_login_path
    end
  rescue StandardError
    redirect_to customer_customer_login_path
  end
end
