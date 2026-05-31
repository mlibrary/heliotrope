# frozen_string_literal: true
require 'open3'
require 'tempfile'

module Hydra::FileCharacterization
  class ToTempFile
    include Open3

    def self.open(filename, data, &block)
      new(filename).call(data, &block)
    end

    attr_reader :filename

    def initialize(filename)
      @filename = filename.is_a?(Array) ? filename.join("") : filename
    end

    def call(data)
      f = Tempfile.new([File.basename(filename), File.extname(filename)])
      begin
        f.binmode
        if data.respond_to? :read
          f.write(data.read)
        else
          f.write(data)
        end
        f.rewind
        yield(f)
      ensure
        data.rewind if data.respond_to? :rewind
        f.close
        f.unlink
      end
    end
  end
end
