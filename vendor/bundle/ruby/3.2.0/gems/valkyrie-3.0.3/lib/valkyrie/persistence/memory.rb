# frozen_string_literal: true
#
module Valkyrie::Persistence
  # Implements the DataMapper Pattern to store metadata in memory
  #
  # @note this adapter is used primarily for testing, and is not recommended
  #   in cases where you want to preserve real data
  module Memory
    require 'valkyrie/persistence/memory/metadata_adapter'
    require 'valkyrie/persistence/memory/persister'
    require 'valkyrie/persistence/memory/query_service'
  end
end
