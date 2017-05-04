# frozen_string_literal: true

module Export
  extend ActiveSupport::Autoload
  autoload :Exporter
  load 'metadata_fields.rb'
end
