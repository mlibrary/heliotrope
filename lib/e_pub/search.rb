# frozen_string_literal: true

require "skylight"

module EPub
  class Search
    include Skylight::Helpers

    # 30 second time out, see HELIO-3890
    # This is really more of a "begin timing out now" then
    # a hard limit due to how the recursive search works...
    TIME_OUT = 30_000

    def initialize(publication)
      @publication = publication
      @start_time = (Time.now.to_f * 1000.0).to_i
    end

    def search(query)
      db_results = EPub::SqlLite.from_publication(@publication).search_chapters(query)
      results_from_chapters(db_results, query)
    end

    instrument_method
    def node_query_match(node, query, offset = 0)
      # node.content.downcase.index(query.downcase, offset)
      # As per #1363, people want us to: "Develop exact term matching"
      # So this for example this will find "music" or "Music" but not "musical"
      # when searching for "music". Any sort of stemming is going to be super hard
      # since we need to parse the DOM for results.
      # Try this for now.
      # node.content.index(/#{query}\W/i, offset)
      # Allowing regexes really messes up CFIs and highlighting and isn't really
      # appropriate for this simple search feature
      node.content.index(/#{Regexp.escape(query)}($|\W)/i, offset)
    end

    private

      instrument_method
      def find_selection(node, query)
        matches = []
        offset = 0

        while node_query_match(node, query, offset)
          pos0 = node.content.index(/#{Regexp.escape(query)}($|\W)/i, offset)
          pos1 = pos0 + query.length

          result = OpenStruct.new

          begin
            result.cfi = EPub::CFI.from(node, pos0, pos1).cfi
          rescue
            Rails.logger.error("EPUB SEARCH ERROR: EPub::CFI.from(#{node}, #{pos0}, #{pos1}).cfi produced an ERROR")
          end

          begin
            result.snippet = EPub::Snippet.from(node, pos0, pos1).snippet
          rescue
            Rails.logger.error("EPUB SEARCH ERROR: EPub::Snippet.from(#{node}, #{pos0}, #{pos1}).snippet produced an ERROR")
          end

          # HELIO-4085
          next if result.cfi.nil?
          next if result.snippet.nil?

          matches << result

          offset = pos1 + 1

          # ::EPub.logger.debug("RETURN IN find_selection: #{print_time}") if timeout?
          return matches if timeout?
        end
        matches
      end

      instrument_method
      def find_targets(node, query)
        targets = []
        return nil unless node_query_match(node, query)

        node.children.each do |child|
          targets << if child.text? && node_query_match(child, query)
                       find_selection(child, query)
                     else
                       find_targets(child, query)
                     end
          # ::EPub.logger.debug("RETURN IN find_targets: #{print_time}") if timeout?
          return targets.compact if timeout?
        end
        targets.compact
      end

      instrument_method
      def results_from_chapters(db_results, query) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        results = {}
        results[:q] = query
        results[:highlight_off] = @publication.multi_rendition
        results[:search_results] = []

        db_results.each do |chapter|
          file = File.join(@publication.root_path, File.dirname(@publication.content_file), chapter[:href])
          # ::EPub.logger.debug("FILE: #{file}")
          doc = Nokogiri::XML(File.open(file))
          doc.remove_namespaces!

          matches = []
          body = doc.xpath("//body")
          body.children.each do |node|
            matches << find_targets(node, query)
            # ::EPub.logger.debug("BREAK IN body.children.each: #{print_time}") if timeout?
            break if timeout?
          end

          matches = matches.flatten.compact
          # ::EPub.logger.debug("MATCHES: #{matches.count}")
          matches.each_index do |index|
            match = matches[index]

            # De-duplicate identical snippets with slightly different CFIs that are neighbors.
            # Since we need the CFIs in the reader for syntax highlighting, still send those,
            # just not snippets
            empty_snippet = "" if match.snippet == matches[index - 1].snippet && matches.length > 1

            results[:search_results].push(cfi: "#{chapter[:basecfi]}#{match.cfi}",
                                          title: chapter[:title],
                                          snippet: empty_snippet || match.snippet)
            # ::EPub.logger.debug("BREAK IN MATCHES:#{print_time}") if timeout?
            break if timeout?
          end
          ::EPub.logger.info("EPUB SEARCH TIMEOUT: #{print_time}") if timeout?
          break if timeout?
        end

        results[:timeout] = timeout? ? print_time : 0

        results
      end

      def print_time
        "#{(Time.now.to_f * 1000.0).to_i - @start_time}"
      end

      def timeout?
        return true if (Time.now.to_f * 1000.0).to_i - @start_time >= TIME_OUT
        false
      end
  end
end
