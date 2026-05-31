# frozen_string_literal: true

module Unicode
  module Types
    VERSION = "1.9.0"
    UNICODE_VERSION = "15.1.0"
    DATA_DIRECTORY = File.expand_path(File.dirname(__FILE__) + "/../../../data/").freeze
    INDEX_FILENAME = (DATA_DIRECTORY + "/types.marshal.gz").freeze
  end
end
