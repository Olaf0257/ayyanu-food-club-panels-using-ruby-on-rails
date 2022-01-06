class AppsettingsController < ApplicationController
  before_action :require_admin_logged_in
  def settings
    appCustomer = get_app_details("customer")
    appBusiness = get_app_details("business")
    appDriver = get_app_details("driver")
    @customerappdetail = appCustomer ? appCustomer : AppDetail.new
    @businessappdetail = appBusiness ? appBusiness : AppDetail.new
    @driverappdetail = appDriver ? appDriver : AppDetail.new
    @serviceAmount = Servicefee.first
    # @adminpercentage = percentage ? percentage : AdminPercentage.new
    render layout: "admin_application"
    end

  def update_app_settings
    if params[:play_store_link].present? && params[:android_version].present? && params[:android_update_type].present? && params[:app_store_link].present? && params[:ios_version].present? && params[:ios_update_type].present?
      app = get_app_details(params[:app_type])
      if app
        app.update(ios_store_link: params[:app_store_link], ios_current_version: params[:ios_version], ios_version_force_update: params[:ios_update_type], android_store_link: params[:play_store_link], android_current_version: params[:android_version], android_version_force_update: params[:android_update_type], app_type: params[:app_type])
      else
        AppDetail.create(ios_store_link: params[:app_store_link], ios_current_version: params[:ios_version], ios_version_force_update: params[:ios_update_type], android_store_link: params[:play_store_link], android_current_version: params[:android_version], android_version_force_update: params[:android_update_type], app_type: params[:app_type])
      end
      flash[:success] = "App Details has been updated successfully!"
    else
      flash[:error] = "All parameters must be present"
    end
    redirect_back(fallback_location: dashboard_path)
    end

  def update_service_amount
    if params[:direct_point_percentage].present? && params[:refferal_point_percentage].present?
      serviceFee = Servicefee.first
      if serviceFee
        serviceFee.update(direct_point_percentage: params[:direct_point_percentage], refferal_point_percentage: params[:refferal_point_percentage])
      else
        Servicefee.create(direct_point_percentage: params[:direct_point_percentage], refferal_point_percentage: params[:refferal_point_percentage])
      end
      flash[:success] = "Service amount has been updated successfully!"
    else
      flash[:error] = "All parameters must be present"
    end
    redirect_back(fallback_location: dashboard_path)
    end
end
