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

  def walk_up_dom(el, cfi, i)
    if el.previous_sibling
      i += 1
      # Keep finding previous siblings to the dom element
      walk_up_dom(el.previous_sibling, cfi, i)
    elsif el.parent.name == "html"
      # If we're at "body" (will always be 4) than we're done
      "/4" + cfi
    else
      # If there are no previous siblings, and we're not yet at "body",
      # then get the parent and look for *it's* previous siblings
      walk_up_dom(el.parent, "/#{i + 1}" + cfi, 0)
    end
  end

  def snippet(e, p0, p1)
    before = e.text[p0 - 30..p0 - 1]
    after  = e.text[p1 + 1..p1 + 30]
    "...#{before}#{e.text[p0..p1]}#{after}..."
  end

  def find_hits(e, q, offset, hits)
    p0 = e.text.downcase.index(q.downcase, offset)
    p1 = p0 + q.length

    hits.push(
      p0: p0,
      p1: p1,
      snippet: snippet(e, p0, p1)
    )

    find_hits(e, q, p1, hits) if e.text.downcase.index(q.downcase, p1)

    hits
  end

  def chapters_from_db(q)
    db_results = []
    stm = @db.prepare "SELECT href, basecfi, chapter_id from chapters where chapters MATCH ?"
    # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
    # In FTS4 it's also a token, so we can just remove it without affecting results
    stm.bind_param 1, q.sub("-", " ")
    rs = stm.execute
    rs.each do |row|
      db_results.push(href: row[0], basecfi: row[1], chapter_id: row[2])
    end
    db_results
  end

  # These articles on CFIs are good:
  # http://matt.garrish.ca/2013/03/navigating-cfis-part-1/
  # http://matt.garrish.ca/2013/12/navigating-cfis-part-2/
  def cfis_from_epub(db_results, q)
    results = {}
    results[:q] = q
    results[:search_results] = [] if db_results.length.positive?

    db_results.each do |r|
      file = File.join(@epub.epub_path, @epub.content_dir, r[:href])
      doc = Nokogiri::XML(File.open(file))
      # ugly xpath for case insensitive searches
      els = doc.search %{//*[contains(translate(text(),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'), "#{q.downcase}")]}

      Rails.logger.debug("EPub Search for #{q} in #{file} found #{els.count}")

      els.each do |e|
        # calculate the cfi of the dom element
        cfi = walk_up_dom(e, "", 0)
        # find all the hits in this element
        hits = find_hits(e, q, 0, [])

        hits.each do |hit|
          results[:search_results].push(
            cfi: "#{r[:basecfi]}#{cfi},/1:#{hit[:p0]},/1:#{hit[:p1]}",
            chapter_id: r[:chapter_id],
            snippet: hit[:snippet]
          )
        end
      end
    end
    results
  end

  def search(q)
    db_results = chapters_from_db(q)
    cfis_from_epub(db_results, q)
  end
end
