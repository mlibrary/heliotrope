# frozen_string_literal: true

module Keycard::Request
  # Factory to simplify creation of Attributes instances. It binds in a list
  # of finders and inspects the Keycard.config.access mode to determine which
  # subclass to use. You can register a factory instance as a service and then
  # use .for instead of naming concrete classes when processing requests.
  class AttributesFactory
    MODE_MAP = {
      direct: DirectAttributes,
      proxy: ProxiedAttributes,
      cosign: CosignAttributes,
      shibboleth: ShibbolethAttributes
    }.freeze

    def initialize(finders: [Keycard::InstitutionFinder.new])
      @finders = finders
    end

    def for(request)
      mode = MODE_MAP[Keycard.config.access.to_sym]
      if mode.nil?
        # TODO: Warn about this once to the appropriate log; probably in a config check, not here.
        # puts "Keycard does not recognize the '#{access}' access mode, using 'direct'."
        mode = DirectAttributes
      end
      mode.new(request, finders: finders)
    end

    private

    attr_reader :finders
  end
end
