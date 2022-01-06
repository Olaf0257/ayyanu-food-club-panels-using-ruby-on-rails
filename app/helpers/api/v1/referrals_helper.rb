module Api::V1::ReferralsHelper
  def get_app_version_details(version, app_type, app)
    AppDetail.find_app_version(version, app_type, app)
  end
end
