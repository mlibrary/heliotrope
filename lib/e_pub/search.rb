# frozen_string_literal: true

require "skylight"

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
      node.content.index(/#{Regexp.escape(query)}($|\W)/i, offset)
    end

    private

      def find_selection(node, query)
        Skylight.instrument title: "FindSelection" do
          matches = []
          offset = 0

          while node_query_match(node, query, offset)
            pos0 = node.content.index(/#{Regexp.escape(query)}($|\W)/i, offset)
            pos1 = pos0 + query.length

            result = OpenStruct.new
            result.cfi = EPub::CFI.from(node, pos0, pos1).cfi
            result.snippet = EPub::Snippet.from(node, pos0, pos1).snippet
            matches << result

            offset = pos1 + 1
          end
          matches
        end
      end

      def find_targets(node, query)
        Skylight.instrument title: "FindTargets" do
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
      end

      def results_from_chapters(db_results, query)
        results = {}
        results[:q] = query
        results[:highlight_off] = @publication.multi_rendition
        results[:search_results] = []

        db_results.each do |chapter|
          Skylight.instrument title: "EpubSearch Text In Each Chapter" do
            file = File.join(@publication.root_path, File.dirname(@publication.content_file), chapter[:href])
            doc = Nokogiri::XML(File.open(file))
            doc.remove_namespaces!

            matches = []
            body = doc.xpath("//body")
            body.children.each do |node|
              matches << find_targets(node, query)
            end

            matches = matches.flatten.compact

            matches.each_index do |index|
              match = matches[index]

              # De-duplicate identical snippets with slightly different CFIs that are neighbors.
              # Since we need the CFIs in the reader for syntax highlighting, still send those,
              # just not snippets
              empty_snippet = "" if match.snippet == matches[index - 1].snippet && matches.length > 1

              results[:search_results].push(cfi: "#{chapter[:basecfi]}#{match.cfi}",
                                            title: chapter[:title],
                                            snippet: empty_snippet || match.snippet)
            end
          end
        end
        results
      end
  end
end
