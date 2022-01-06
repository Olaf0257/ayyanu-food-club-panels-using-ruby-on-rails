require_relative 'boot'

require 'rails/all'
require 'net/http'
require 'openssl'
require 'resolv-replace'
require 'roo'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FoodDelivery
  class Application < Rails::Application
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any,
        expose:  ['access-token', 'expiry', 'token-type', 'uid', 'client'],
        methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.active_job.queue_adapter = :sidekiq
    config.time_zone = 'Kuwait'
    config.load_defaults 5.1
    config.autoload_paths += %W(#{config.root}/lib)
    # config.cache_store = :redis_store, "redis://localhost:6379/0/cache", { expires_in: 90.minutes }
    config.before_configuration do
	    env_file = File.join(Rails.root, 'config', 'configuration.yml')
	      YAML.load(File.open(env_file)).each do |key, value|
	      ENV[key.to_s] = value
	    end if File.exists?(env_file)
	  end
  end
end
