# frozen_string_literal: true

module EPub
  class Rendition
    private_class_method :new

    # Class Methods

    def self.from_publication_unmarshaller_container_rootfile(publication, unmarshaller_rootfile)
      return null_object unless publication&.instance_of?(Publication) && unmarshaller_rootfile&.instance_of?(Unmarshaller::Rootfile)
      new(publication, unmarshaller_rootfile)
    end

    def self.null_object
      RenditionNullObject.send(:new)
    end

    # Instance Methods

    def sections
      return @sections unless @sections.nil?
      @sections = []
      @unmarshaller_rootfile.content.nav.tocs.each do |toc|
        next unless /toc/i.match?(toc.id)
        toc.headers.each do |header|
          next if header.text.blank?
          next if /.*#.*/.match?(header.href)
          idref, index = @unmarshaller_rootfile.content.idref_with_index_from_href(header.href)
          args = {
            title: header.text,
            depth: header.depth,
            cfi: "/6/#{index * 2}[#{idref}]!",
            downloadable: @publication.downloadable?,
            unmarshaller_chapter: @unmarshaller_rootfile.content.chapter_from_title(header.text)
          }
          @sections << Section.from_rendition_args(self, args)
        end
        break
      end
      @sections
    end

    def label
      @label ||= @unmarshaller_rootfile.label
    end

    private

      def initialize(publication, unmarshaller_rootfile)
        @publication = publication
        @unmarshaller_rootfile = unmarshaller_rootfile
      end
  end

  class RenditionNullObject < Rendition
    private_class_method :new

    private

      def initialize
        super(Publication.null_object, Unmarshaller::Rootfile.null_object)
      end
  end
end
