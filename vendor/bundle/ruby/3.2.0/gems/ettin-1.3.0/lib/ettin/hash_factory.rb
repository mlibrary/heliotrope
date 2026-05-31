# frozen_string_literal: true

require "deep_merge/rails_compat"
require "ettin/deep_transform"
require "ettin/source"

module Ettin

  # Loads and deeply merges targets into a hash structure.
  class HashFactory
    def build(*targets)
      hash = Hash.new(nil)
      targets
        .flatten
        .map {|target| Source.for(target) }
        .map(&:load)
        .map {|h| h.deep_transform_keys {|key| key.to_s.to_sym } }
        .each {|h| hash.deeper_merge!(h, overwrite_arrays: true) }
      hash
    end
  end
end
