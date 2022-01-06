class Api::V1::ReferralsController < Api::ApiController
  before_action :authenticate_api_access, only: [:generate_referral]

  def generate_referral
    @user.update(referral: "#{@user.name.first(1)}#{@user.id}#{request.headers['HTTP_ACCESSTOKEN'].first(5)}") if @user.referral.blank?
    responce_json(code: 200, referral_url: referral_url(@user.referral), referred_persons: @user.referrals.select { |r| User.find_by(email: r.email).present? }.as_json)
  end

  def app_version_check
    app_details = get_app_version_details(params[:current_version], params[:app_type], params[:app])
    responce_json(app_details)
  end

  def latest_app_version
    if params[:app_type].present? && params[:app].present?
      app_detail = AppDetail.find_by(app_type: params[:app_type])
      latest_app_version = params[:app] == "ios" ? app_detail.ios_current_version : app_detail.android_current_version
      responce_json(code: 200, app_version: latest_app_version)
    else
      responce_json(code: 422, message: "App Detail not found")
    end
  end

  def update_latest_app_version
    if params[:app_type].present? && params[:app].present? && params[:version].present?
      app_detail = AppDetail.find_by(app_type: params[:app_type])

      if params[:app] == "ios"
        app_detail.update(ios_current_version: params[:version])
      else
        app_detail.update(android_current_version: params[:version])
      end

      responce_json(code: 200, message: "Successfully updated!")
    else
      responce_json(code: 422, message: "App Detail or Version not found")
    end
  end
end
