require 'rack/ldp'
require 'sinatra/base'

module RDF
  ##
  # A basic implementation of an LDP Server.
  class Lamprey < Sinatra::Base
    use Rack::Lint
    use Rack::LDP::ContentNegotiation
    use Rack::LDP::Errors
    use Rack::LDP::Responses
    use Rack::ConditionalGet
    use Rack::LDP::Requests

    get '/*' do
      if settings.repository.empty?
        RDF::LDP::Container
          .new(RDF::URI(request.url), settings.repository)
          .create(StringIO.new, 'text/turtle')
      end

      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    patch '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    post '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    put '/*' do
      begin
        RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
      rescue RDF::LDP::NotFound
        model = request.env.fetch('HTTP_LINK', '')

        RDF::LDP::Resource
          .interaction_model(model)
          .new(RDF::URI(request.url), settings.repository)
      end
    end

    options '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    head '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    delete '/*' do
      RDF::LDP::Resource.find(RDF::URI(request.url), settings.repository)
    end

    ##
    # @example Configuring Lamprey server
    #   Lamprey::Config
    #     .register_repository!(:my_repo, RDF::Repository)
    #
    #   Lamprey::Config.configure!(repository: :my_repo)
    class Config
      ##
      # @see #new
      # @see #configure!
      def self.configure!(**options)
        new(**options).configure!
      end

      ##
      # Registers a repository for use with the {#build_repository} method.
      #
      # @example Registering a custom repository
      #   MyRepository = Class.new(RDF::Repository)
      #
      #   Lamprey::Config.register_repository!(:my_repo, MyRepository)
      #
      # @param name  [Symbol]
      # @param klass [Class]
      # @return [void]
      def self.register_repository!(name, klass)
        @@repositories[name] = klass
      end

      ##
      # @!attribute [rw] options
      attr_accessor :options

      @@repositories = { default: RDF::Repository }

      ##
      # @param repository [RDF::Repository]
      def initialize(repository: :default)
        @options = {}
        @options[:repository] = repository
      end

      ##
      # Builds the repository as given in the configuration.
      #
      # @return [RDF::Repository] a repository instance
      def build_repository
        @@repositories.fetch(options[:repository]) do
          warn "#{options[:repository]} is not a configured repository. Use "\
               '`Lamprey::Config.register_repository!` to register it before '\
               'configuration. Falling back on the default: ' \
               "#{@@repositories[:default]}."
          @@repositories[:default]
        end.new
      end

      ##
      # Configures {RDF::Lamprey} with {#options}.
      #
      # @return [void]
      def configure!
        repository = build_repository
        unless repository.persistent?
          warn "#{repository} is not a persistent repository. "\
               'Data will be lost on server shutdown.'
        end

        RDF::Lamprey.configure { |config| config.set :repository, repository }
      end
    end

    # Set defaults in case user does not configure values
    Config.configure!

    run! if app_file == $PROGRAM_NAME
  end
end
