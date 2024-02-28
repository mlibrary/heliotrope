# frozen_string_literal: true

require 'pragmatic_segmenter'
require "skylight"

# This class is supposed to show the search term in context, so surrounded
# by sentences (not sentence fragments). It's unfortunatly a little involved...

module EPub
  class Snippet
    private_class_method :new
    attr_accessor :node, :pos0, :pos1
    include Skylight::Helpers

    # This is not an "exact" length, but will be used as sort of a
    # guideline. Weird snippets might still sneak through...
    SNIPPET_LENGTH = 120

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

    instrument_method
    def snippet
      original_text = node.text
      # mark the hit without using markup in a really dumb way
      node.content = if node.text.length < @pos1 + 1
                       node.text.insert(@pos0, "{{{HIT~") + "~HIT}}}"
                     else
                       node.content = node.text.insert(@pos0, "{{{HIT~").insert(@pos1 + 8, "~HIT}}}")
                     end
      # get some surrounding text if possible
      fragment = text_available(node)
      # attempt (poorly) to remove footnotes
      fragment = remove_possible_footnotes(fragment)
      # adjust if there's too much text
      text = adjust_length(fragment.text.squish)

      # remove the hit indicator
      text.gsub!('{{{HIT~', '')
      text.gsub!('~HIT}}}', '')

      # Important! Clean up the original node! It's global to the EPub::Publication
      node.content = original_text

      text
    end

    private

      def adjust_length(text) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # We want words around the hit to give context.
        # Prefer sentences.
        # Prefer context to surround the hit evenly, before and after as opposed
        # to having more context up front or more context after (I guess?).
        # Prefer whole words, not bits of words.

        sentences = PragmaticSegmenter::Segmenter.new(text: text).segment

        # PragmaticSegmenter will turn this: {{{HIT~Honk!~HIT}}} into this: ["{{{HIT~Honk!", "~HIT}}}"]
        # which makes sense since the search term contains a sentence terminator. So just find the hit
        # using the first "{{{HIT~" part.
        idx = sentences.find_index { |s| s =~ /{{{HIT~/ }

        rvalue = ""
        # The characters: "{{{HIT~~HIT}}}" = 14
        if sentences[idx].length > SNIPPET_LENGTH + 14
          # Break up a big sentence
          rvalue = shorten(sentences[idx])
        else
          # Add to a smaller sentence
          # Return it if it's all we have
          return sentences[idx] if sentences.length == 1
          if sentences.length == 2
            rvalue = shorten(sentences.join(" "))
          else
            context = sentences[idx]
            context = context + " " + sentences[idx + 1] if sentences[idx + 1].present?
            context = sentences[idx - 1] + " " + context if sentences[idx - 1].present? && sentences[idx - 1] != sentences.last
            rvalue = shorten(context)
          end
        end

        rvalue
      end

      def shorten(str) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        before, hit, after = str.partition(/\s?{{{HIT~.*~HIT}}}\s?/)
        befores = before.split(" ")
        afters = after.split(" ")
        if befores.join(" ").length > afters.join(" ").length
          # more context before the hit, reduce it
          until (befores.join(" ") + hit + afters.join(" ")).length <= SNIPPET_LENGTH + 14 || befores.length == 0
            befores.shift
          end
        else
          # more context after the hit, reduce it
          until (befores.join(" ") + hit + afters.join(" ")).length <= SNIPPET_LENGTH + 14 || afters.length == 0
            afters.pop
          end
        end

        rvalue = befores.join(" ") + hit + afters.join(" ")
        return rvalue unless rvalue.length > SNIPPET_LENGTH + 14
        # If it's still too long, shorten the other end too.
        return rvalue if befores == 0 && afters == 0 # but short-circuit if something very wrong is happening
        shorten(rvalue)
      end

      def remove_possible_footnotes(fragment) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Recursivly examine text and elements in the fragment.
        # If there's a sentence end, immediatly followed by a link (no whitespace
        # in between), remove the link and it's contents. This will probably not go well.
        # Hopefully it will work most of the time. There is no reliable markup
        # for footnotes across epubs so this is all best guess.
        # This should work for:
        # <p>Here is a footnote!<a href="#">99</a></p>
        # <p>Bob says "Here is a footnote."<a href="#">99</a></p>
        # <p>There is a footnote?<sup><a href="#">99</a></sup></p>
        # ...
        # Classic whack-a-mole.
        fragment.children.each do |node|
          if node.try(:text?)
            if node.next && node.next.name == "a"
              node.next.remove if sentence_ending(node.text)
            end
            if node.next && node.next.name == "sup" && node.next.children[0]&.name == "a"
              node.next.remove if sentence_ending(node.next.previous_sibling.text)
            end
          end
          remove_possible_footnotes(node) unless node.children.empty?
        end
        fragment
      end

      def sentence_ending(text) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Without AI, this will never be right.
        # But maybe it will work with basic english most of the time.
        # If a footnote happens in the middle of a sentence, there's no way
        # to differentiate it from a normal link. Oh well.
        return true if text.strip.ends_with?('.')
        return true if text.strip.ends_with?('?')
        return true if text.strip.ends_with?('!')
        return true if text.strip.ends_with?('."')
        return true if text.strip.ends_with?('?"')
        return true if text.strip.ends_with?('!"')
        return true if text.strip.ends_with?('.”')
        return true if text.strip.ends_with?('?”')
        return true if text.strip.ends_with?('!”')
        return true if text.strip.ends_with?('.’”') # yeah, this happens
        false
      end

      def text_available(node)
        return node if node.text.squish.length >= SNIPPET_LENGTH
        text_available(node.parent)
      end

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
  end
end
