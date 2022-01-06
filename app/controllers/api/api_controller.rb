class Api::ApiController < ActionController::Base
  # before_action :configure_permitted_parameters, if: :devise_controller?
  # before_action :check_for_force_update
  # protect_from_forgery with: :null_session

  include Api::ApiHelper
  include ApplicationHelper

  def validate_role
    role = %w[customer business manager transporter kitchen_manager]
    unless role.include? params[:role]
      render json: { code: 422, message: "Invalid role!" }
    end
  end

  private

  def authenticate_api_access
    authenticate_guest_access
  end

  def authenticate_guest_access
    api_key = request.headers["HTTP_ACCESSTOKEN"]
    serverSession = ServerSession.where(server_token: api_key).first
    @user = User.find(params[:cart_user_id]) if params[:cart_user_id].present?
    @user ||= serverSession.auth.user
  rescue StandardError
    @user = nil
    @guestToken = request.headers["HTTP_GUESTTOKEN"]
    if @guestToken.blank?
      render json: { code: 346, message: "Your session has expired. Please login again." }
    end
  end

  # def configure_permitted_parameters
  #   devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :contact, :country_code,:password) }
  # end

  def _set_current_session
    accessor = instance_variable_get(:@_request)
    Act
  end
end
