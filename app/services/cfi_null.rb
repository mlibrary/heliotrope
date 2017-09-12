# frozen_string_literal: true

require 'nokogiri'

class CfiNull < Cfi
  attr_reader :node, :query, :pos0, :pos1, :section

  def initialize
    @node = Nokogiri.XML(nil)
    @query = ""
    @pos0 = -1
    @pos1 = -1
    @section = -1
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
