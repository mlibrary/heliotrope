# frozen_string_literal: true
module Valkyrie
  # Define a wrapper namespace for test resources.
  module Specs
  end
end
require 'valkyrie/specs/shared_specs/persister.rb'
require 'valkyrie/specs/shared_specs/queries.rb'
require 'valkyrie/specs/shared_specs/metadata_adapter'
require 'valkyrie/specs/shared_specs/resource.rb'
require 'valkyrie/specs/shared_specs/storage_adapter.rb'
require 'valkyrie/specs/shared_specs/change_set_persister.rb'
require 'valkyrie/specs/shared_specs/file.rb'
require 'valkyrie/specs/shared_specs/change_set.rb'
require 'valkyrie/specs/shared_specs/solr_indexer.rb'
# Write-only tests.
require 'valkyrie/specs/shared_specs/write_only/metadata_adapter.rb'
