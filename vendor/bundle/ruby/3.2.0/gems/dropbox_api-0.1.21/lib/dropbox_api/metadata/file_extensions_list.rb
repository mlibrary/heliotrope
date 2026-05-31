# frozen_string_literal: true

module DropboxApi::Metadata
  class FileExtensionsList < Array
    def initialize(data)
      if !data.is_a?(Array) || data.any? { |v| !v.is_a? String }
        raise ArgumentError, "Invalid extension list: #{data.inspect}."
      end

      super(data)
    end
  end
end
