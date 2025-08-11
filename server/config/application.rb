require_relative "boot"

require "rails"
# Required for .megabytes method
require "active_support/core_ext/numeric/bytes"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# Require ActiveSupport core extensions for numeric methods like .megabytes
require "active_support/core_ext/numeric/bytes"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Server
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    config.autoload_paths += %W(#{config.root}/app/lib)

    config.cache_store = :memory_store, { size: 32.megabytes }

    config.api_only = true
  end
end
