# frozen_string_literal: true

module API
  class Version
    attr_reader :version, :default

    def initialize(version, default = false)
      @version = version
      @default = default
    end

    def matches?(request)
      accept = request.headers[:accept]
      return default if accept.blank?
      return true if /application\/vnd\.heliotrope\.#{version}\+json/.match?(accept)
      return false if /application\/vnd\.heliotrope\..*\+json/.match?(accept)
      default
    end
  end
end
