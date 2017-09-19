# frozen_string_literal: true

require 'nokogiri'

class CfiNull < Cfi
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
