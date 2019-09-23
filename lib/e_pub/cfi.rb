# frozen_string_literal: true

module EPub
  class CFI
    # "Ugh! EPUB CFIs..."
    # http://matt.garrish.ca/2013/03/navigating-cfis-part-1/
    # http://matt.garrish.ca/2013/12/navigating-cfis-part-2/

    def self.from(node, pos0 = nil, pos1 = nil)
      if node.is_a?(Nokogiri::XML::Text) && !node.content.strip.empty? && pos0.integer? && pos1.integer?
        # when finding the cfi for text within an element
        Text.new(node, pos0, pos1)
      elsif node.is_a?(Nokogiri::XML::Element)
        # when finding the cfi of an element
        Element.new(node)
      else
        NullObject.new(node)
      end
    end

    def cfi(node)
      indexes = []
      this = node
      # walk up the dom to determine the cfi
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
    end

    def initialize(node, pos0 = nil, pos1 = nil)
      @node = node
      @pos0 = pos0
      @pos1 = pos1
    end
  end

  class CFI
    class Text < CFI
      def cfi
        indexes = super(@node.parent)
        "/4/#{indexes.join('/')},#{text_range(@node, @pos0, @pos1)}"
      end

      def text_section(node)
        count = -1
        node.parent.children.each do |child|
          # AFAIK "section" text should always be odd, only elements are even
          count += 2 if child.text?
          return count if child == node
        end
      end

      def text_range(node, pos0, pos1)
        section = text_section(node)
        "/#{section}:#{pos0},/#{section}:#{pos1}"
      end
    end
  end

  class CFI
    class Element < CFI
      def cfi
        indexes = super(@node)
        return "/4/1:0" if indexes.length.zero?
        "/4/#{indexes.join('/')}"
      end
    end
  end

  class CFI
    class NullObject < CFI
      def cfi
        "/"
      end
    end
  end
end
