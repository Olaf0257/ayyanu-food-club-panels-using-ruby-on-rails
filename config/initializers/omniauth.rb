Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Rails.application.secrets["google_client_id"], Rails.application.secrets["google_client_secret"]
  provider :facebook, Rails.application.secrets["facebook_app_id"], Rails.application.secrets["facebook_app_secret"]
  provider :instagram, Rails.application.secrets["instagram_app_id"], Rails.application.secrets["instagram_app_secret"]
end