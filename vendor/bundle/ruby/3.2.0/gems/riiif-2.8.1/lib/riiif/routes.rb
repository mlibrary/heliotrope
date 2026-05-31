module Riiif
  class Routes
    ALLOW_DOTS ||= /[\w.]+/
    SIZES ||= /(!|pct:)?[\w.,]+/

    def initialize(router, options)
      @router = router
      @options = options
    end

    def add_routes(&blk)
      @router.instance_exec(@options, &blk)
    end

    def draw
      add_routes do |options|
        resource = options.fetch(:resource)
        route_prefix = options[:at]
        route_prefix ||= "/#{options[:as]}" if options[:as]
        get "#{route_prefix}/:id/:region/:size/:rotation/:quality.:format" => 'riiif/images#show',
            constraints: { rotation: ALLOW_DOTS, size: SIZES },
            defaults: { format: 'jpg', rotation: '0', region: 'full', quality: 'default', model: resource },
            as: options[:as] || 'image'

        get "#{route_prefix}/:id/info.json" => 'riiif/images#info',
            defaults: { format: 'json', model: resource },
            as: [options[:as], 'info'].compact.join('_')

        match "#{route_prefix}/:id/info.json" => 'riiif/images#info_options',
              via: [:options]

        # This doesn't work presently
        # get "#{route_prefix}/:id", to: redirect("#{route_prefix}/%{id}/info.json")
        get "#{route_prefix}/:id" => 'riiif/images#redirect', as: [options[:as], 'base'].compact.join('_')
      end
    end
  end
end
