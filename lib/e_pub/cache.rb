# frozen_string_literal: true

module EPub
  class Cache
    private_class_method :new

    def self.cache(id, _epub_zip)
      return unless ::EPub.noid?(id)
      purge(id) if cached?(id)
      EPubsService.cache_epub(id)
    end

    def self.cached?(id)
      return false unless ::EPub.noid?(id)
      Dir.exist?(EPubsService.epub_path(id))
    end

    def self.clear
      EPubsService.clear_cache
    end

    def self.publication(id)
      return Publication.null_object unless ::EPub.noid?(id)
      return Publication.null_object unless cached?(id)
      Publication.from(id)
    end

    def self.prune(_time_delta = 1.day)
      EPubsService.prune_cache
    end

    def self.purge(id)
      return unless ::EPub.noid?(id)
      EPubsService.prune_cache_epub(id)
    end
  end
end
