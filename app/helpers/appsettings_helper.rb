module AppsettingsHelper
  def get_app_details(app_type)
    AppDetail.where(app_type: app_type).first
  end

  def app_ios_json(pletfrom)
    pletfrom.as_json(only: [:id, :ios_store_link, :ios_current_version, :ios_version_force_update])
  end

  def app_android_json(pletfrom)
    pletfrom.as_json(only: [:id, :android_store_link, :android_current_version, :android_version_force_update])
  end
end
