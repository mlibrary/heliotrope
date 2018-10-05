# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Heliotrope
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.generators do |g|
      g.test_framework :rspec, spec: true
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_job.queue_adapter = :resque

    # Add concerns to autoload paths
    config.autoload_paths += %W[#{config.root}/app/presenters/concerns]

    # Add lib directory to autoload paths
    config.autoload_paths << "#{config.root}/lib"
    config.autoload_paths << "#{config.root}/lib/devise"

    # For properly generating URLs and minting DOIs - the app may not by default
    # Outside of a request context the hostname needs to be provided.
    config.hostname = Settings.host

    # Set default host
    Rails.application.routes.default_url_options[:host] = config.hostname

    # URL for logging the user in via shibbolleth
    config.shibboleth_identity_provider_url = Settings.shibboleth_identity_provider_url

    # Affirmative login means that we only log someone into the application
    # when they actively initiate a login, even if they have an SSO session
    # that we recognize and could log them in automatically.
    #
    # Auto login means that, if we ever access a protected resource (such that
    # the Devise authenticate_user! filter is called), we will automatically
    # sign the user into the application if they have an SSO session active.
    #
    # See the KeycardAuthenticatable strategy for more detail.
    config.auto_login = false

    # Disable automatic account creation on Cosign logins unless
    # enabled in config/settings.
    config.create_user_on_login = Settings.create_user_on_login && true

    # Use EPub Checkpoint authorization otherwise EPub Legacy authorization
    config.e_pub_checkpoint_authorization = Settings.e_pub_checkpoint_authorization && true

    # Never use /tmp, always use ~/tmp, #627 and http://stackoverflow.com/a/17068331
    tmpdir = Rails.root.join('tmp').to_s
    ENV['TMPDIR'] = tmpdir

    # Set the epub engine for cozy-sun-bear
    config.cozy_epub_engine = 'epubjs'

    config.to_prepare do
      # ensure overrides are loaded
      # see https://bibwild.wordpress.com/2016/12/27/a-class_eval-monkey-patching-pattern-with-prepend/
      Dir.glob(Rails.root.join('app', '**', '*_override*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
  end
end
