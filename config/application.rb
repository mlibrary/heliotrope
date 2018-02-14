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

    # URL for logging the user out of Cosign
    config.cosign_logout_url = Settings.cosign_logout_url

    # Never use /tmp, always use ~/tmp, #627 and http://stackoverflow.com/a/17068331
    tmpdir = Rails.root.join('tmp').to_s
    ENV['TMPDIR'] = tmpdir

    # Set the epub engine for cozy-sun-bear
    config.cozy_epub_engine = 'epubjs'

    config.to_prepare do
      # See the release notes for Hyrax 2 for an explanation of this Module#prepend
      # FileSetsControllerBehavior is in the services directory
      Hyrax::FileSetsController.prepend FileSetsControllerBehavior
      # DownloadsControllerBehavior is in the services directory
      Hyrax::DownloadsController.prepend DownloadsControllerBehavior
    end
  end
end
