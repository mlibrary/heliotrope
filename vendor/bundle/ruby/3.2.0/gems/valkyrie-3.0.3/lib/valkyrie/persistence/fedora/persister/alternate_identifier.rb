# frozen_string_literal: true
require 'valkyrie/resource'
require 'valkyrie/types'

module Valkyrie::Persistence::Fedora
  # Class modeling alternate identifiers as first-order Valkyrie::Resources
  # Alternate identifiers generalize identifiers from external systems
  # Examples include NOIDs, ARKs, and EZIDs
  # @see https://confluence.ucop.edu/display/Curation/NOID
  # @see http://n2t.net/e/ark_ids.html
  # @see https://ezid.cdlib.org/learn/#01
  class AlternateIdentifier < ::Valkyrie::Resource
    attribute :references, ::Valkyrie::Types::ID.optional
  end
end
