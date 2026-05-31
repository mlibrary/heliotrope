module BlacklightOaiProvider
  class Routes
    def initialize(defaults = {})
      @defaults = defaults
    end

    def call(mapper, _options = {})
      mapper.match 'oai', action: 'oai', via: [:get, :post]
    end
  end
end
