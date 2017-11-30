# frozen_string_literal: true

module EPub
  class Cfi
    # "Ugh! EPUB CFIs..."
    # http://matt.garrish.ca/2013/03/navigating-cfis-part-1/
    # http://matt.garrish.ca/2013/12/navigating-cfis-part-2/

    private_class_method :new
    attr_accessor :node, :query, :pos0, :pos1, :section

    def self.from(node, query, offset)
      if node.text? && !node.content.strip.empty? && !query.empty? && offset.integer?
        new(node, query, offset)
      else
        null_object
      end
    end

    def self.null_object
      CfiNullObject.send(:new)
    end

    def range
      "/#{@section}:#{@pos0},/#{@section}:#{@pos1}"
    end

    def cfi
      # walk up the dom elements to determine the CFI of the node
      indexes = []
      this = @node.parent

      while this && this.name != "body"
        # for the hierarchy, we only care about elements
        siblings = this.parent.element_children
        idx = siblings.index(this)

        indexes << if this.text?
                     idx + 1
                   else
                     (idx + 1) * 2
                   end

        indexes[-1] = "#{indexes[-1]}[#{this['id']}]" if this['id']

        this = this.parent
      end
      indexes.reverse!
      # "body" is always 4
      "/4/#{indexes.join('/')},#{range}"
    end

    private

      def initialize(node, query, offset)
        @node = node
        @query = query
        @section = node.parent.children.index(node) + 1
        @pos0 = node.content.index(/#{query}\W/i, offset)
        @pos1 = @pos0 + query.length
      end
  end

  class CfiNullObject < Cfi
    attr_reader :node, :query, :pos0, :pos1, :section

    def initialize
      @node = Nokogiri.XML(nil)
      @query = ""
      @pos0 = ""
      @pos1 = ""
      @section = ""
    end

    def range
      ""
    end

    def snippet
      ""
    end

    def cfi
      ""
    end
  end
end
