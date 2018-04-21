# frozen_string_literal: true

module API
  # Advanced routing constraint matched against request accept header.
  # @see http://guides.rubyonrails.org/routing.html#advanced-constraints
  # @example Two Version Routing Constraints: 'v2' and 'v1' (default)
  #   Rails.application.routes.draw do
  #     namespace :api, constraints: ->(req) { req.format == :json } do
  #       scope module: :v2, constraints: API::Version.new('v2') do
  #         get 'resource', controller: :resources, action: :find, as: :find_resource
  #       end
  #       scope module: :v1, constraints: API::Version.new('v1', true) do
  #         get 'resource', controller: :resources, action: :find, as: :find_resource
  #       end
  #     end
  #   end
  # @example Version 'v2' Matching Request Accept Header
  #   accept: "application/json, application/vnd.heliotrope.v2+json"
  # @example Version 'v1' Matching Request Accept Header
  #   accept: "application/json, application/vnd.heliotrope.v1+json"
  # @example Default Version Matching Request Accept Header
  #   accept: "application/json"
  class Version
    # Version being matched against
    # @return [String] version prefix string
    attr_reader :version
    # Default version flag
    # @return [Boolean] true if default version
    attr_reader :default

    # Assign instance to Rails routing constraints: option
    # @param [String] version to match against
    # @param [Boolean] default is the default version?
    def initialize(version, default = false)
      @version = version
      @default = default
    end

    # Called by Rails with the request object as an argument
    # @param [ActionDispatch::Request] request request object
    # @return [true] if explicit version match against request accept header
    # @return [false] if explicit version mismatch against request accept header
    # @return [default] if no explicit version match/mismatch against request accept header
    def matches?(request)
      accept = request.headers[:accept]
      return default if accept.blank?
      return true if /application\/vnd\.heliotrope\.#{version}\+json/.match?(accept)
      return false if /application\/vnd\.heliotrope\..*\+json/.match?(accept)
      default
    end
  end
end
