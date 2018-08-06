# frozen_string_literal: true

module EPub
  class Rendition
    private_class_method :new

    # Class Methods

    def self.from_rootfile_element(publication, rootfile_element)
      return null_object unless publication&.instance_of?(Publication) && rootfile_element&.instance_of?(Nokogiri::XML::Element)
      new(publication, rootfile_element)
    end

    def self.null_object
      RenditionNullObject.send(:new)
    end

    # Instance Methods

    def sections
      return @sections unless @sections.nil?
      @sections = []
      content.nav.tocs.each do |toc|
        next unless toc.id == 'toc'
        toc.headers.each.with_index do |header|
          idref, index = content.idref_with_index_from_href(header.href)
          args = {
            title: header.text || '',
            depth: header.depth || 0,
            cfi: "/6/#{index * 2}[#{idref}]!",
            # Currently only fixed layout epubs can have downloadable sections.
            # For reflowable/non-page-image epubs, we'll need a different process,
            # probably something like headless-chrome.
            downloadable: @publication.multi_rendition?
          }
          @sections << Section.from_hash(@publication, args) if args[:title].present?
        end
      end
      @sections
    end

    def label
      @label ||= @rootfile_element&.attribute('label')&.text || ''
    end

    private

      def initialize(publication, rootfile_element)
        @publication = publication
        @rootfile_element = rootfile_element
      end

      def content
        return @content unless @content.nil?
        full_path = @rootfile_element&.attribute('full-path')&.value
        @content = if full_path
                     Unmarshaller::Content.from_full_path(File.join(@publication.root_path, full_path))
                   else
                     Unmarshaller::Content.null_object
                   end
      end
  end

  class RenditionNullObject < Rendition
    private_class_method :new

    private

      def initialize
        super(Publication.null_object, Nokogiri::XML::Element.new('rootfile', Nokogiri::XML::Document.parse(nil)))
      end
  end
end
