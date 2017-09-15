# frozen_string_literal: true

require 'nokogiri'

class EPubsSearchService
  attr_reader :db, :epub

  def initialize(id)
    EPubsServiceJob.perform_now(id) unless File.directory? EPubsService.epub_path(id)
    @epub = EPubsIndexService::EPub.new(EPubsService.epub_path(id))
    @db = SQLite3::Database.new "#{EPubsService.epub_path(id)}/#{id}.db"
  rescue SQLite3::Exception => e
    raise "Unable to create #{EPubsService.epub_path(id)}/#{id}.db, #{e}"
  end

  def chapters_from_db(query)
    db_results = []
    stm = @db.prepare "SELECT href, basecfi, chapter_id from chapters where chapters MATCH ?"
    # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
    # In FTS4 it's also a token, so we can just remove it without affecting results
    stm.bind_param 1, query.sub("-", " ")
    rs = stm.execute
    rs.each do |row|
      db_results.push(href: row[0], basecfi: row[1], chapter_id: row[2])
    end
    db_results
  end

  def find_selection(node, query)
    matches = []
    offset = 0

    while node.content.downcase.index(query.downcase, offset)
      cfi = Cfi.from(node, query, offset)
      matches.push(
        cfi: cfi.cfi,
        snippet: cfi.snippet
      )
      offset = cfi.pos1 + 1
    end
    matches
  end

  def find_targets(node, query)
    targets = []
    return nil unless node.content.downcase.index(query.downcase)

    node.children.each do |child|
      targets << if child.text? && child.text.downcase.index(query.downcase)
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
    results[:search_results] = [] if db_results.length.positive?

    db_results.each do |chapter|
      file = File.join(@epub.epub_path, @epub.content_dir, chapter[:href])
      doc = Nokogiri::XML(File.open(file))
      doc.remove_namespaces!

      matches = []
      body = doc.xpath("//body")
      body.children.each do |node|
        matches << find_targets(node, query)
      end

      matches.flatten.compact.each do |match|
        results[:search_results].push(
          cfi: "#{chapter[:basecfi]}#{match[:cfi]}",
          chapter_id: chapter[:chapter_id],
          snippet: match[:snippet]
        )
      end
    end
    results
  end

  def search(query)
    db_results = chapters_from_db(query)
    results_from_chapters(db_results, query)
  end
end
