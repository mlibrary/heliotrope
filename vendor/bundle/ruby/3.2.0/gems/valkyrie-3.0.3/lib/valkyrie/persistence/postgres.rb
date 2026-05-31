# frozen_string_literal: true
# :nocov:
begin
  gem 'pg'
  gem 'activerecord'
rescue Gem::LoadError => e
  raise Gem::LoadError,
        "You are using the Postgres adapter without installing the #{e.name} gem.  "\
        "Add `gem '#{e.name}'` to your Gemfile."
end
# :nocov:
module Valkyrie::Persistence
  # Implements the DataMapper Pattern to store metadata into Postgres
  module Postgres
    require 'active_record'
    require 'valkyrie/persistence/postgres/metadata_adapter'
  end
end
