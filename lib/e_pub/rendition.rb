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

    def intervals
      return @intervals unless @intervals.nil?
      @intervals = []
      @unmarshaller_rootfile.content.nav.tocs.each do |toc|
        next unless /toc/i.match?(toc.id)
        toc.headers.each do |header|
          next if header.text.blank?
          idref, index = @unmarshaller_rootfile.content.idref_with_index_from_href(header.href)
          cfi = if /.*#.*/.match?(header.href)
            # Don't use the CFI for multi level TOCs that have url fragments/anchors where
            # the TOC might be very large and take a long time to calculate all the CFIs. See HELIO-2461
            file_url(header.href)
          else
            "/6/#{index * 2}[#{idref}]!/4/1:0"
          end
          args = {
            title: header.text,
            depth: header.depth,
            cfi: cfi,
            unmarshaller_chapter: @unmarshaller_rootfile.content.chapter_from_title(header.text)
          }
          @intervals << Interval.from_rendition_args(self, args)
        end
        break
      end
      @intervals
    end

    def label
      @label ||= @unmarshaller_rootfile.label
    end

    private
      def file_url(href)
        # This works due to a change in CSB
        # https://github.com/mlibrary/cozy-sun-bear/commit/8875fb87669d23363d5bb6bb244f291a13793971
        # "/#{File.dirname(@publication.content_file)}/#{href.gsub('#', '%23')}"
        root_array = Pathname(@unmarshaller_rootfile.container.root_path).each_filename.to_a
        nav_array = Pathname(@unmarshaller_rootfile.content.nav.full_path).each_filename.to_a
        path_array = nav_array - root_array
        "/#{File.dirname(File.join(path_array))}/#{href.gsub('#', '%23')}"
      end

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
