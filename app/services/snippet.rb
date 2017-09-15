# frozen_string_literal: true

class Snippet
  private_class_method :new
  attr_accessor :node, :pos0, :pos1

  SNIPPET_PAD = 50

  def self.from(node, pos0, pos1)
    if node.try(:text?) && pos0.integer? && pos1.integer?
      new(node, pos0, pos1)
    else
      SnippetNull.send(:new)
    end
  end

  def snippet
    "...#{before}#{@node.text[@pos0..@pos1]}#{after}..."
  end

  private

    def after
      text = @node.text[@pos1 + 1..@node.text.length] || ""
      text += after_sibling_text
      text[0..SNIPPET_PAD]
    end

    def after_sibling_text
      if @node.next_sibling.present? && @node.next_sibling.text
        @node.next_sibling.text
      elsif @node.parent.next_sibling.present? && @node.parent.next_sibling.text
        @node.parent.next_sibling
      else
        ""
      end
    end

    def before
      text = if @pos0.zero?
               ""
             else
               @node.text[0..@pos0 - 1]
             end

      text = before_sibling_text + text

      front = if text.length < SNIPPET_PAD
                text.length
              else
                SNIPPET_PAD
              end

      text[text.length - front..text.length]
    end

    def before_sibling_text
      if @node.previous_sibling.present? && @node.previous_sibling.text
        @node.previous_sibling.text
      elsif @node.parent.previous_sibling.present? && @node.parent.previous_sibling.text
        @node.parent.previous_sibling.text
      else
        ""
      end
    end

    def initialize(node, pos0, pos1)
      @node = node
      @pos0 = pos0
      @pos1 = pos1
    end
end
