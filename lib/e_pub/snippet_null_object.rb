# frozen_string_literal: true

require 'nokogiri'

module EPub
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
  end
end
