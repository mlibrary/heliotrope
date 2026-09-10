# frozen_string_literal: true

module Keycard
  module Request
    # Memoizes Keycard::Request::Attributes#all for the life of the instance.
    #
    # HELIO-4633. Attributes#all re-runs every finder on every call:
    #
    #   def all
    #     base.merge!(external).delete_if { |_k, v| v.nil? || v == "" }
    #   end
    #
    # and Attributes#[] is just `all[attr]`, so each `request_attributes[:foo]`
    # re-queries the Keycard database. A single Fulcrum page fires that dozens
    # of times -- DlpsInstitution#find and DlpsInstitutionAffiliation#find read
    # two keys apiece, Auth#initialize forces four lazy methods, and
    # Actorable#licenses calls #affiliations once per institution.
    #
    # An Attributes instance wraps one immutable Rack request, so the answer
    # cannot change between calls. Memoizing removes the redundant queries, and
    # with them most of the exposure to a connection going bad mid-request.
    #
    # The result is frozen because callers are expected to read it: #[],
    # #identity, and #supplemental all derive new objects from it.
    module MemoizedAttributes
      def all
        @all ||= deep_freeze(super)
      end

      private

        def deep_freeze(value)
          case value
          when Hash
            value.each { |key, item| deep_freeze(key); deep_freeze(item) }
          when Array
            value.each { |item| deep_freeze(item) }
          end
          value.freeze
        end
    end
  end
end
