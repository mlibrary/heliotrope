# frozen_string_literal: false

module Hyrax
  module CitationsBehaviors
    module TitleBehavior
      include Hyrax::CitationsBehaviors::CommonBehavior

      TITLE_NOCAPS = ["a", "an", "and", "but", "by", "for", "it", "of", "the", "to", "with"].freeze
      EXPANDED_NOCAPS = TITLE_NOCAPS + ["about", "across", "before", "without"]

      def chicago_citation_title(title_text)
        process_title_parts(title_text) do |w, index|
          if (index.zero? && w.casecmp(w).zero?) || (w.length > 1 && w.casecmp(w).zero? && !EXPANDED_NOCAPS.include?(w))
            maybe_split_on_hyphens(w)
          else
            w
          end
        end
      end

      def mla_citation_title(title_text)
        process_title_parts(title_text) do |w|
          if TITLE_NOCAPS.include? w
            w
          else
            maybe_split_on_hyphens(w)
          end
        end
      end

      def process_title_parts(title_text, &block)
        if block_given?
          title_text.split(" ").collect.with_index(&block).join(" ")
        else
          title_text
        end
      end

      def setup_title_info(work, escape = true)
        text = ''
        title = work.to_s
        if title.present?
          title = CGI.escapeHTML(title) if escape
          title_info = clean_end_punctuation(title.strip)
          text << title_info
        end

        return nil if text.strip.blank?
        clean_end_punctuation(text.strip) + "."
      end

      # this method to stop "non-word" hyphens being removed ;-)
      # https://tools.lib.umich.edu/jira/browse/HELIO-2088
      def maybe_split_on_hyphens(word)
        if word.scan(/-/).count == word.length
          word
        else
          # the split("-") will handle the capitalization of hyphenated words
          word.split("-").map! { |x| ucfirst(x) }.join("-")
        end
      end

      # https://tools.lib.umich.edu/jira/browse/HELIO-1991
      def ucfirst(word)
        # to_s in case word is an empty string as it was for "non-word" hypens before HELIO-2088
        word.slice(0, 1).capitalize + word.slice(1..-1).to_s
      end
    end
  end
end
