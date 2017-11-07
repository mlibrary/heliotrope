# frozen_string_literal: true

module Import
  extend ActiveSupport::Autoload
  autoload :Importer
  autoload :CSVParser
  autoload :RowData
  load 'metadata_fields.rb'
end
