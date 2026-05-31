# frozen_string_literal: true

module Keycard::Request
  # Base class for extracting attributes from a Rack request.
  #
  # This provides the interface for attribute extraction, independent of how
  # the application is served and accessed. It is not intended to be used
  # directly; you should use {AttributesFactory} to create an appropriate
  # subclass based on configuration.
  #
  # The overall design is that a subclass will extract various attributes
  # from the request headers and environment, and a set of attribute finders
  # may be supplied to examine the base set and add additional attributes.
  class Attributes
    IDENTITY_ATTRS = %i[user_pid user_eid].freeze

    def initialize(request, finders: [])
      @request = request
      @finders = finders
    end

    # The user's persistent identifier.
    #
    # If the client has authenticated as a user, this will be a peristent
    # identifier suitable as a key for an application account. It is
    # expressly opaque, meaning that it cannot be assumed to be resolvable
    # to a person or be useful for display purposes. It can be relied on to
    # be stable for the same person as the identity provider determines that.
    def user_pid
      nil
    end

    # The user's enterprise identifier.
    #
    # If the client has authenticated as a user and the identity provider has
    # releases one, this will be the "enterprise" identifier, some string that
    # is useful for display and resolving to a person. It will tend to be
    # something recognizable to that person, such as a network ID or email
    # address. It may be helpful for displaying who is logged in or looking
    # up directory information, for example. It should not be assumed to be
    # permanent; that is, the EID may change for a person (and PID), so this
    # should not used as a database key, for example.
    def user_eid
      nil
    end

    # The user's IP address.
    #
    # This will be a string version of the IP address of the client, whether
    # or not they have been proxied.
    def client_ip
      nil
    end

    # The token supplied by the user via auth_param according to RFC 7235. Typically,
    # this is the API token.
    def auth_token
      Keycard::Token.rfc7235(safe("HTTP_AUTHORIZATION"))
    end

    # The set of base attributes for this request.
    #
    # Subclasses should implement user_pid, user_eid, and client_ip
    # and include them in the hash under those keys.
    def base
      {
        user_pid: user_pid,
        user_eid: user_eid,
        client_ip: client_ip,
        auth_token: auth_token
      }
    end

    def [](attr)
      all[attr]
    end

    def all
      base.merge!(external).delete_if { |_k, v| v.nil? || v == "" }
    end

    def external
      finders
        .map { |finder| finder.attributes_for(self) }
        .reduce({}) { |hash, attrs| hash.merge!(attrs) }
    end

    def identity
      all.select { |k, _v| identity_keys.include?(k.to_sym) }
    end

    def supplemental
      all.reject { |k, _v| identity_keys.include?(k.to_sym) }
    end

    def identity_keys
      @identity_keys ||= IDENTITY_ATTRS + finders.map(&:identity_keys).flatten
    end

    private

    # Retrieve the value from the request's environment for a given key.
    #
    # This will trim whitespace and yield nil for empty values or those with
    # the special value of '(null)'. Use {#safe} if you always want a string.
    #
    # @return [String|nil] value for the key, filtered and trimmed to nil
    def get(key)
      scrub request.env[key]
    end

    # Retrieve a guaranteed string value from the request's environment for a
    # given key.
    #
    # This has the same behavior as {#get}, except that it will coalesce
    # missing values to an empty string, convenient if you need to do string
    # operations like splitting the value.
    def safe(key)
      get(key) || ""
    end

    # Scrub a value to remove whitespace, filter the special '(null)' value,
    # and translate resulting empty strings to nil.
    def scrub(value)
      str = (value || "").strip
      case str
      when nil, "(null)", ""
        nil
      else
        str
      end
    end

    attr_reader :finders
    attr_reader :request
  end
end
