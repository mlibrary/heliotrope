# frozen_string_literal: false

module Hyrax
  module CitationsBehaviors
    module NameBehavior
      include Hyrax::CitationsBehaviors::CommonBehavior
      # return all unique authors with end punctuation removed
      def author_list(work, escape = true)
        all_authors(work) { |author| clean_end_punctuation(escape ? CGI.escapeHTML(author) :  author) }
      end

      # return all unique authors of a work or nil if none
      def all_authors(work, &block)
        authors = work.creator.uniq.compact
        block_given? ? authors.map(&block) : authors
      end

      def given_name_first(name)
        name = clean_end_punctuation(name)
        return name unless name =~ /,/
        temp_name = name.split(/,\s*/)
        temp_name.last + " " + temp_name.first
      end

      def abbreviate_name(name)
        abbreviated_name = ''
        name = name.join('') if name.is_a? Array
        # make sure we handle "Cher" correctly (Hyrax comment)
        # Heliotrope doesn't want abbreviation/reversal of corporate names (Stuff like 'BIG MUSEUM') in citations,...
        # which to the original code in NameBehavior appears like a person's name that needs to be reversed.
        # abbreviate_name() used to call another method, surname_first(), but our human names are "reversed" already.
        # We won't be calling surname_first() here or in the other places it was used.
        # If our names are not reversed on ingest/entry, that's a metadata issue we should detect, and stuff like...
        # these "corporarte names with a space" will probably need to be flagged in that process and OK'ed somehow.
        # see https://tools.lib.umich.edu/jira/browse/HELIO-3186
        return name unless name.include?(',')
        name_segments = name.split(/,\s*/)
        abbreviated_name << name_segments.first
        abbreviated_name << ", #{name_segments.last.first}" if name_segments[1]
        abbreviated_name << "."
      end
    end
  end
end
