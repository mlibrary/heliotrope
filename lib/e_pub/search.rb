# frozen_string_literal: true

module EPub
  class Search
    def initialize(publication)
      @publication = publication
    end

    def search(query)
      db_results = EPub::SqlLite.from_publication(@publication).search_chapters(query)
      results_from_chapters(db_results, query)
    end

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
      node.content.index(/#{Regexp.escape(query)}\W/i, offset)
    end

    private

      def find_selection(node, query)
        matches = []
        offset = 0

        while node_query_match(node, query, offset)
          cfi = EPub::Cfi.from(node, query, offset)
          snippet = EPub::Snippet.from(node, cfi.pos0, cfi.pos1).snippet
          # Sometimes the search term will be in the same sentence twice (or more),
          # creating identical snippets with slightly different CFIs.
          # This seems pointless so exlude identical snippets from search results.
          unless matches.map(&:snippet).include? snippet
            result = OpenStruct.new
            result.cfi = cfi.cfi
            result.snippet = snippet
            matches << result
          end
          offset = cfi.pos1 + 1
        end
        matches
      end

      def find_targets(node, query)
        targets = []
        return nil unless node_query_match(node, query)

        node.children.each do |child|
          targets << if child.text? && node_query_match(child, query)
                       find_selection(child, query)
                     else
                       find_targets(child, query)
                     end
        end
        targets.compact
      end

      def results_from_chapters(db_results, query)
        results = {}
        results[:q] = query
        results[:search_results] = []

        db_results.each do |chapter|
          file = File.join(@publication.root_path, File.dirname(@publication.content_file), chapter[:href])
          doc = Nokogiri::XML(File.open(file))
          doc.remove_namespaces!

          matches = []
          body = doc.xpath("//body")
          body.children.each do |node|
            matches << find_targets(node, query)
          end

          matches.flatten.compact.each do |match|
            results[:search_results].push(cfi: "#{chapter[:basecfi]}#{match.cfi}",
                                          title: chapter[:title],
                                          snippet: match.snippet)
          end
        end
        results
      end
  end
end
