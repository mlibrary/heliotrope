# frozen_string_literal: true

require 'pragmatic_segmenter'

# This class is supposed to show the search term in context, so surrounded
# by sentences (not sentence fragments). It's unfortunatly a little involved...

module EPub
  class Snippet
    private_class_method :new
    attr_accessor :node, :pos0, :pos1

    SNIPPET_LENGTH = 50

    def self.from(node, pos0, pos1)
      if node.try(:text?) && pos0.integer? && pos1.integer?
        new(node, pos0, pos1)
      else
        null_object
      end
    end

    def self.null_object
      SnippetNullObject.send(:new)
    end

    def snippet
      # We're only going to get at most 3 sentences for context with the middle
      # sentence containing the search term. Some people write really long sentences
      # though... not sure how great this will be...
      sentences = parse_sentences(parse_fragments(parent_paragraph(@node)))
      sentences.join(" ")
    end

    def parent_paragraph(current_node)
      until current_node.name == "p" || current_node.name == "body"
        current_node = current_node.parent
      end
      current_node
    end

    def parse_fragments(para, fragments = [])
      para.children.each do |child|
        if child.text?
          fragment = OpenStruct.new
          fragment.text = child.text
          # This is really cheesy, adding the string "{{{HIT}}}"
          # to track the fragment with the actual search string
          # in it compared to the text of the rest of the paragraph.
          # We need a way to know which sentence the search query
          # is in without using markup/nokogiri.
          fragment.text.insert(@pos0 - 1, "{{{HIT}}}") if child == @node
          fragments << fragment
        elsif child.name == "sup" && child.children[0].name == "a"
          # Footnotes seem to really mess up sentence determinations, so skip them
          # These might be marked up differently in different epubs so this is a WIP
          # http://www.idpf.org/epub/30/spec/epub30-contentdocs.html#sec-contentdocs-vocab-association
          next
        else
          parse_fragments(child, fragments)
        end
      end
      fragments.map(&:text).join("")
    end

    def parse_sentences(text)
      sentences = PragmaticSegmenter::Segmenter.new(text: text).segment
      rvalue = []
      sentences.each_index do |i|
        if sentences[i].match?(/\{\{\{HIT\}\}\}/)
          sentences[i].gsub!(/\{\{\{HIT\}\}\}/, '')
          rvalue = determine_size(sentences, i)
        end
      end
      rvalue
    end

    def determine_size(sentences, i)
      # Trying to determine the right size snippet and which sentences
      # out of a possible 3 to return. Fairly terrible.
      first = sentences[i - 1]
      hit   = sentences[i]
      last  = sentences[i + 1]
      if sentences.length == 1
        [hit]
      elsif hit.length > SNIPPET_LENGTH
        [hit]
      elsif sentences.length == 2
        if last.nil?
          [first, hit]
        else
          [hit, last]
        end
      else
        [first, hit, last]
      end
    end

    private

      def initialize(node, pos0, pos1)
        @node = node
        @pos0 = pos0
        @pos1 = pos1
      end
  end

  class SnippetNullObject < Snippet
    attr_reader :node, :pos0, :pos1

    def initialize
      @node = Nokogiri::XML(nil)
      @pos0 = ""
      @pos1 = ""
    end

    def snippet
      ""
    end

    def parse_sentences
      []
    end

    def parent_paragraph
      Nokogiri::XML("<html><p></p></html>").xpath("//p")[0]
    end

    def parse_fragments
      ""
    end
  end
end
