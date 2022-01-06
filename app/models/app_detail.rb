class AppDetail < ApplicationRecord
  def as_json(options = {})
    super(options.merge(except: [:created_at, :updated_at]))
  end

  def self.find_app_version(version, app_type, app)
    # app_version = version.split(', ').last
    app_details = find_by(app_type: app_type)
    if app_details
      database_version = app == "ios" ? app_details.ios_current_version : app_details.android_current_version
      status = app == "ios" ? app_details.ios_version_force_update : app_details.android_version_force_update
      if database_version > version
        { code: 200, update_type: status == true ? "force" : "normal" }
        # {code: 200,update_type: status == true ? 'force' : 'normal'}
      elsif database_version == version
        { code: 200, update_type: "no_update" }
        # {code: 200,update_type: 'no_update'}
      end
    else
      { code: 200, update_type: "no_update" }
    end
  end
end
