# frozen_string_literal: false

module Hyrax
  module CitationsBehaviors
    module Formatters
      class ChicagoFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior
        def format(work)
          text = ""
          # setup formatted author list
          authors_list = all_authors(work)
          text << format_authors(authors_list)
          text = "<span class=\"citation-author\">#{text}</span>" if text.present?
          text << format_title(work.to_s)
          pub_info = setup_pub_info(work, true)
          text << " #{whitewash(pub_info)}." if pub_info.present?
          text << " #{work.citable_link}."
          text << (work.pdf_ebook? ? ' PDF.' : ' EPUB.')
        end

        def format_authors(authors_list = [])
          return '' if authors_list.blank?
          text = ''
          text << surname_first(authors_list.first) if authors_list.first
          authors_list[1..6].each_with_index do |author, index|
            text << if index + 2 == authors_list.length # we've skipped the first author
                      ", and #{given_name_first(author)}."
                    else
                      ", #{given_name_first(author)}"
                    end
          end
          text << " et al." if authors_list.length > 7
          # if for some reason the first author ended with a comma
          text.gsub!(',,', ',')
          text << "." unless text =~ /\.$/
          whitewash(text)
        end
        # rubocop:enable Metrics/MethodLength

        def format_date(pub_date); end

        def format_title(title_info)
          return "" if title_info.blank?
          title_text = chicago_citation_title(title_info)
          title_text << '.' unless title_text =~ /\.$/
          title_text = whitewash(title_text)
          " <i class=\"citation-title\">#{title_text}</i>"
        end

        private

          def whitewash(text)
            Loofah.fragment(text.to_s).scrub!(:whitewash).to_s
          end
      end
    end
  end
end
