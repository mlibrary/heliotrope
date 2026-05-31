# frozen_string_literal: true
require 'mime/types'

module Hydra::Derivatives
  class TempfileService
    def self.create(file, &block)
      new(file).tempfile(&block)
    end

    attr_reader :source_file

    def initialize(source_file)
      @source_file = source_file
    end

    def tempfile(&block)
      if source_file.respond_to? :to_tempfile
        source_file.send(:to_tempfile, &block)
      elsif source_file.has_content?
        default_tempfile(&block)
      end
    end

    def default_tempfile(&_block)
      Tempfile.open(filename_for_characterization) do |f|
        f.binmode
        if source_file.content.respond_to? :read
          f.write(source_file.content.read)
        else
          f.write(source_file.content)
        end
        source_file.content.rewind if source_file.content.respond_to? :rewind
        f.rewind
        yield(f)
      end
    end

    def filename_for_characterization
      registered_mime_type = MIME::Types[source_file.mime_type].first
      Logger.warn "Unable to find a registered mime type for #{source_file.mime_type.inspect} on #{source_file.uri}" unless registered_mime_type
      extension = registered_mime_type ? ".#{registered_mime_type.extensions.first}" : ''
      version_id = 1 # TODO: fixme
      m = %r{/([^/]*)$}.match(source_file.uri)
      ["#{m[1]}-#{version_id}", extension.to_s]
    end
  end
end
