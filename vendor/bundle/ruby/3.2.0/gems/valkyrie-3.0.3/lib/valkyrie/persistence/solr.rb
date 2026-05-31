# frozen_string_literal: true
# :nocov:
begin
  gem 'rsolr'
rescue Gem::LoadError => e
  raise Gem::LoadError,
        "You are using the Solr adapter without installing the #{e.name} gem.  "\
        "Add `gem '#{e.name}'` to your Gemfile."
end
# :nocov:
module Valkyrie::Persistence
  # Implements the DataMapper Pattern to store metadata into Solr
  module Solr
    require 'valkyrie/persistence/solr/metadata_adapter'
    require 'valkyrie/persistence/solr/composite_indexer'
  end
end
