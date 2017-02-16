module Import
  extend ActiveSupport::Autoload
  autoload :DummyUser
  autoload :MonographBuilder
  autoload :FileSetBuilder
  autoload :Importer
  autoload :CSVParser
  autoload :RowData
  load 'metadata_fields.rb'
end
