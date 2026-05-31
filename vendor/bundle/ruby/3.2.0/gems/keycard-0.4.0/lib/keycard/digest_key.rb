# frozen_string_literal: true

require "digest"
require "securerandom"

# A typical digest or api key, ready to be encrypted.
class Keycard::DigestKey
  class HiddenKeyError < StandardError; end
  HIDDEN_KEY = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

  # To simply mint a new key, call #new without any parameters.
  # For wrapping existing, deserialized keys, pass the digest to the constructor.
  # @param digest [String] The value of the hashed key
  # @param key [String] Use this if you'd like to specify the unhashed key.
  #   If a digest is also provided, this parameter is ignored.
  def initialize(digest = nil, key: nil)
    if digest
      @digest = digest
    else
      @key = key || SecureRandom.uuid
    end
  end

  # A string representation of this key. For hidden keys, this returns an
  # obfuscated value.
  # @return [String]
  def to_s
    @key || HIDDEN_KEY
  end

  # The unhashed value of the key.
  # @return [String]
  # @raise [HiddenKeyError] This exception is raised if the unhashed key is
  #   not available.
  def value
    @key || raise(HiddenKeyError, "Cannot display hashed/hidden keys")
  end

  # The result of hashing the key
  # @return [String]
  def digest
    @digest ||= Digest::SHA256.hexdigest(@key)
  end

  def eql?(other)
    digest == if other.is_a?(self.class)
      other.digest
    else
      other.to_s
    end
  end
  alias_method :==, :eql?
end
