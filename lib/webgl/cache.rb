# frozen_string_literal: true

require 'zip'

module Webgl
  class Cache
    private_class_method :new

    def self.cache(id, webgl)
      return unless ::Valid.noid?(id)
      purge(id) if cached?(id)
      begin
        Zip::File.open(webgl) do |zip_file|
          zip_file.each do |entry|
            # We don't want to include the root directory, it could be
            # named anything. We want the root to be named by the noid
            parts = entry.name.split(File::SEPARATOR)
            without_parent = parts.slice(1, parts.length).join(File::SEPARATOR)
            ::Webgl.make_path_entry(id, without_parent)
            entry.extract(::Webgl.path_entry(id, without_parent))
          end
        end
      rescue Zip::Error
        raise "Webgl #{id} is corrupt."
      end
    end

    def self.cached?(id)
      return false unless ::Valid.noid?(id)
      Dir.exist?(::Webgl.path(id))
    end

    def self.clear
      FileUtils.rm_rf(Dir.glob(File.join(::Webgl.root, "*"))) if Dir.exist?(::Webgl.root)
    end

    def self.purge(id)
      return unless ::Valid.noid?(id)
      FileUtils.rm_rf(::Webgl.path(id)) if Dir.exist?(::Webgl.path(id))
    end
  end
end
