# frozen_string_literal: true
# :nocov:
begin
  gem 'ldp'
rescue Gem::LoadError => e
  raise Gem::LoadError,
        "You are using the Fedora adapter without installing the #{e.name} gem.  "\
        "Add `gem '#{e.name}'` to your Gemfile."
end
# :nocov:
module Valkyrie::Persistence
  # Implements the DataMapper Pattern to store metadata into Fedora
  module Fedora
    require 'ldp'
    require 'valkyrie/persistence/fedora/permissive_schema'
    require 'valkyrie/persistence/fedora/metadata_adapter'
    require 'valkyrie/persistence/fedora/persister'
    require 'valkyrie/persistence/fedora/query_service'
    require 'valkyrie/persistence/fedora/ordered_list'
    require 'valkyrie/persistence/fedora/ordered_reader'
    require 'valkyrie/persistence/fedora/list_node'

    DEFAULT_FEDORA_VERSION = 5
  end
end
