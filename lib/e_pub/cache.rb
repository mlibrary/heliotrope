# frozen_string_literal: true

require 'zip'

module EPub
  class Cache
    private_class_method :new

    def self.cache(id, epub)
      return unless ::Valid.noid?(id)
      purge(id) if cached?(id)
      begin
        Zip::File.open(epub) do |zip_file|
          zip_file.each do |entry|
            ::EPub.make_path_entry(id, entry.name)
            entry.extract(::EPub.path_entry(id, entry.name)) # unless File.exist?(::EPub.path_entry(id, entry.name))
          end
        end
      rescue Zip::Error
        raise "EPUB #{id} is corrupt."
      end
    end

    def self.cached?(id)
      return false unless ::Valid.noid?(id)
      Dir.exist?(::EPub.path(id))
    end

    def self.clear
      FileUtils.rm_rf(Dir.glob(File.join(::EPub.root, "*"))) if Dir.exist?(::EPub.root)
    end

    def self.publication(id)
      return Publication.null_object unless ::Valid.noid?(id)
      return Publication.null_object unless cached?(id)
      Publication.from(id)
    end

    def self.purge(id)
      return unless ::Valid.noid?(id)
      FileUtils.rm_rf(::EPub.path(id)) if Dir.exist?(::EPub.path(id))
    end
  end
end
