# frozen_string_literal: true

module EPub
  class Chapter
    attr_accessor :id, :href, :basecfi, :doc, :publication
    private_class_method :new

    # Class Methods
    def self.null_object
      ChapterNullObject.send(:new)
    end

    private

      def initialize(opts)
        @id = opts[:id]
        @href = opts[:href]
        @basecfi = opts[:basecfi]
        @doc = opts[:doc]
        @publication = opts[:publication]
      end
  end

  class ChapterNullObject < Chapter
    private_class_method :new


    private

      def initialize; end
  end
end
