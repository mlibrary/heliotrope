# frozen_string_literal: true

module EPub
  class EPub
    private_class_method :new

    attr_reader :id

    def self.from(epub, options = {})
      id = if epub.is_a?(Hash) && epub.key?(:id) && epub[:id].present?
             epub[:id]
           else
             epub
           end
      return EPub.null_object unless ::EPub.noid?(id&.to_s)
      new(id.to_s)
    rescue StandardError => e
      ::EPub.logger.info("### INFO epub from #{epub} with options #{options} raised #{e} ###")
      EPub.null_object
    end

    def self.null_object
      EPubNullObject.send(:new)
    end

    def read(file_entry = "META-INF/container.xml")
      return EPub.null_object.read(file_entry) unless Cache.cached?(id)
      EPubsService.read(id, file_entry)
    rescue StandardError => e
      ::EPub.logger.info("### INFO read #{file_entry} not found in epub #{id} raised #{e} ###")
      EPub.null_object.read(file_entry)
    end

    def search(query)
      return EPub.null_object.search(query) unless Cache.cached?(id)
      EPubsSearchService.new(id).search(query)
    rescue StandardError => e
      ::EPub.logger.info("### INFO query #{query} in epub #{id} raised #{e} ###")
      EPub.null_object.search(query)
    end

    private

      def initialize(id)
        @id = id
        EPubsService.open(@id) # cache epub
      end
  end
end
