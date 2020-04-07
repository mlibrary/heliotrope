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

    # Affirmative login means that we only log someone into the application
    # when they actively initiate a login, even if they have an SSO session
    # that we recognize and could log them in automatically.
    #
    # session[:log_me_in] flag is set true when login initiated by user
    #
    # See the KeycardAuthenticatable strategy for more detail.

    # Auto login means that, if we ever access a protected resource (such that
    # the Devise authenticate_user! filter is called), we will automatically
    # sign the user into the application if they have an SSO session active.
    #
    # See the KeycardAuthenticatable strategy for more detail.
    config.auto_login = Settings.auto_login && true

    # Automatic account creation on login
    # Should we create users automatically on first login?
    # This supports convenient single sign-on account provisioning
    #
    # See the KeycardAuthenticatable strategy for more detail.
    config.create_user_on_login = Settings.create_user_on_login && true

    # Never use /tmp, always use ~/tmp, #627 and http://stackoverflow.com/a/17068331
    tmpdir = Rails.root.join('tmp').to_s
    ENV['TMPDIR'] = tmpdir

    # Set the epub engine for cozy-sun-bear
    config.cozy_epub_engine = 'epubjs'

    # See https://github.com/mlibrary/umrdr/commit/4aa4e63349d6f3aa51d76f07aa20faeae6712719
    config.skylight.probes -= ['middleware']

    # Development Model Tree Flag
    config.model_tree = Settings.model_tree && true

    config.to_prepare do
      # ensure overrides are loaded
      # see https://bibwild.wordpress.com/2016/12/27/a-class_eval-monkey-patching-pattern-with-prepend/
      Dir.glob(Rails.root.join('app', '**', '*_override*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Here we swap out some of the default actor stack, from Hyrax, located
      # (in Hyrax itself) at app/services/default_middleware_stack.rb

      # Insert actor after obtaining lock so we are first in line!
      Hyrax::CurationConcern.actor_factory.insert_after(Hyrax::Actors::OptimisticLockValidator, HeliotropeActor)
      # Maybe register DOIs on update
      Hyrax::CurationConcern.actor_factory.insert_after(HeliotropeActor, RegisterFileSetDoisActor)
      # Heliotrope "importer" style CreateWithFilesActor
      Hyrax::CurationConcern.actor_factory.insert_after(RegisterFileSetDoisActor, CreateWithImportFilesActor)
      # Destroy FeaturedRepresentatives on delete
      Hyrax::CurationConcern.actor_factory.insert_after(Hyrax::Actors::CleanupTrophiesActor, FeaturedRepresentativeActor)
      # Delete ModelTreeVertices and ModelTreeEdges
      Hyrax::CurationConcern.actor_factory.insert_after(FeaturedRepresentativeActor, ModelTreeActor)
    end
  end
end
