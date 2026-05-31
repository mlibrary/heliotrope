# frozen_string_literal: true
module Valkyrie::Persistence::Postgres
  module ORM
    # ActiveRecord class which the Postgres adapter uses for persisting data.
    # @!attribute id
    #   @return [UUID] ID of the record
    # @!attribute metadata
    #   @return [Hash] Hash of all metadata.
    # @!attribute created_at
    #   @return [DateTime] Date created
    # @!attribute updated_at
    #   @return [DateTime] Date updated
    # @!attribute internal_resource
    #   @return [String] Name of {Valkyrie::Resource} model - used for casting.
    #
    class Resource < ActiveRecord::Base
      def disable_optimistic_locking!
        @disable_optimistic_locking = true
      end

      def locking_enabled?
        return false if @disable_optimistic_locking
        true
      end
    end
  end
end
