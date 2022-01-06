source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '01f92d86d15d85cfd0f20dabd025dcbd36a8a60f'
gem "axlsx", "~> 2.0"
gem "axlsx_rails"
gem "barby", "~> 0.6.8"
gem "bcrypt", "~> 3.1.7"
gem "bootstrap-sass"
gem "bullet", group: "development"
gem "carrierwave"
gem "chronic"
gem "city-state", "~> 0.1.0"
gem "ckeditor_rails"
gem "cloudinary"
gem "coffee-rails", "~> 4.2"
gem "country_state_select", "~> 3.0", ">= 3.0.5"
gem "crack"
gem "devise"
gem "dropbox-sdk-v2"
gem "exception_notification", "~> 4.3"
gem "fcm"
gem 'toastr-rails'
gem "firebase"
gem "geocoder"
gem "geokit", "~> 1.11"
gem "httparty", "~> 0.13.7"
gem "httpclient", "~> 2.7", ">= 2.7.1"
gem "imagekitio"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "jquery-ui-rails"
gem 'mysql2', '~> 0.5.0'
gem "nokogiri", ">=1.7.0"
gem "omniauth-facebook", "~> 6.0"
gem "omniauth-google-oauth2", "~> 0.8.0"
gem "omniauth-instagram", "~> 1.3"
gem "pry-rails"
# gem "puma", "~> 3.7"
gem "pusher"
gem "rack-cors", require: "rack/cors"
gem "rails", "5.2.0"
gem "remotipart", "~> 1.2"
gem "roo"
gem "roo-xls", "~> 1.2"
gem "rqrcode"
gem "rubocop", "~> 0.55.0"
gem "sass-rails", "~> 5.0"
gem "sidekiq", "< 5"
gem "sidekiq-cron", "~> 0.4.5"
gem "sidekiq-failures"
gem "sidekiq-status"
gem "sidekiq-scheduler"
gem 'rails-assets-sweetalert2', '~> 5.1.1', source: 'https://rails-assets.org'
gem 'sweet-alert2-rails'
gem "twilio-ruby", "~> 5.20"
gem "uglifier", ">= 1.3.0"
gem "will_paginate", ">= 3.1"
gem "will_paginate-bootstrap"
gem "select2-rails"
gem 'cocoon'
gem 'cups'
gem 'cupsffi'
gem 'numbers_and_words'
gem 'bs4_datetime_picker'
gem 'font-awesome-rails'

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capybara", "~> 2.13"
  gem "rails-erd"
  gem "rspec-rails", "~> 3.8"
  gem "selenium-webdriver"
  # gem 'brakeman'
  # gem "rubycritic", require: false
end

group :development do
  gem "letter_opener"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "web-console", ">= 3.3.0"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'momentjs-rails'
gem "aws-sdk-s3", require: false
gem 'unicorn'
ruby "2.5.0"
