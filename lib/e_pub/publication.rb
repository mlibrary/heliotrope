# frozen_string_literal: true

module EPub
  class Publication
    private_class_method :new

    attr_reader :id

    # Class Methods

    def self.from(epub, options = {})
      id = if epub.is_a?(Hash) && epub.key?(:id) && epub[:id].present?
             epub[:id]
           else
             epub
           end
      return Publication.null_object unless ::EPub.noid?(id&.to_s)
      new(id.to_s)
    rescue StandardError => e
      ::EPub.logger.info("### INFO publication from #{epub} with options #{options} raised #{e} ###")
      Publication.null_object
    end

    def self.null_object
      PublicationNullObject.send(:new)
    end

    # Instance Methods

    def chapters
      [Chapter.send(:new)]
    end

    def read(file_entry = "META-INF/container.xml")
      return Publication.null_object.read(file_entry) unless Cache.cached?(id)
      EPubsService.read(id, file_entry)
    rescue StandardError => e
      ::EPub.logger.info("### INFO read #{file_entry} not found in publication #{id} raised #{e} ###")
      Publication.null_object.read(file_entry)
    end

    def presenter
      PublicationPresenter.send(:new, self)
    end

    def search(query)
      return Publication.null_object.search(query) unless Cache.cached?(id)
      EPubsSearchService.new(id).search(query)
    rescue StandardError => e
      ::EPub.logger.info("### INFO query #{query} in publication #{id} raised #{e} at: e.backtrace[0] ###")
      Publication.null_object.search(query)
    end

    private

      def initialize(id)
        @id = id
        EPubsService.open(@id) # cache publication
      end
  end
end
