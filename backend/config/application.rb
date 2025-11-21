# frozen_string_literal: true

require_relative 'boot'
require 'rails'
require 'action_controller/railtie'
require 'active_model/railtie'
require 'active_support/all'

Bundler.require(*Rails.groups)

module LibraryBackend
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.autoload_paths << Rails.root.join('lib')

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        cors_origin = ENV.fetch('CORS_ORIGIN', 'http://localhost:5173')
        origins cors_origin
        resource '*', headers: :any, methods: %i[get post put patch delete options head],
                 credentials: cors_origin != '*'
      end
    end
  end
end
