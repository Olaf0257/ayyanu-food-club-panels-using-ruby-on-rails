require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq/web'


Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
  config.redis = {:url => ENV["REDIS_URL"] || "redis://127.0.0.1:6379/0" }
  config.failures_max_count = false
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.redis = {:url => ENV["REDIS_URL"] || "redis://127.0.0.1:6379/0" }
  config.failures_max_count = false
end

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["#{ENV['FOODCLUBE_SIDEKIQ_USER']}", "#{ENV['FOODCLUBE_SIDEKIQ_PASSWORD']}"]
end
