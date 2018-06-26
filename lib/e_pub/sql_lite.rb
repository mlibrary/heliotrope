# frozen_string_literal: true

require 'sqlite3'

module EPub
  class SqlLite
    private_class_method :new
    attr_accessor :epub_publication, :db

    def self.from_directory(root_path)
      return null_object unless File.exist? root_path
      from_publication(EPub::Publication.from_directory(root_path))
    end

    def self.from_publication(epub_publication)
      db = SQLite3::Database.new File.join(epub_publication.root_path, "#{epub_publication.id}.db")
      new(epub_publication, db)
    rescue StandardError => e
      ::EPub.logger.info("SqlLite.from_directory(#{epub_publication} raised #{e} #{e.backtrace}")
      null_object
    end

    def self.null_object
      SqlLiteNullObject.send(:new)
    end

    def create_table
      @db.execute "CREATE VIRTUAL TABLE chapters USING FTS4(chapter_id, chapter_href, title, basecfi, text)"
    rescue SQLite3::Exception => e
      raise "Unable to create VIRTUAL TABLE 'chapters' in #{@db.filename}, #{e}"
    end

    def load_chapters
      @epub_publication.chapters_from_file.each do |c|
        text = c.doc.search('//text()').map(&:text).delete_if { |x| x !~ /\w/ }
        @db.execute "INSERT INTO chapters VALUES (?, ?, ?, ?, ?)", c.id, c.href, c.title, c.basecfi, text.join(" ")
      end
    rescue SQLite3::Exception => e
      raise "Unable to load chapters to #{@db.filename}, #{e}"
    end

    def search_chapters(query)
      db_results = []
      stm = @db.prepare "SELECT chapter_href, basecfi, title from chapters where chapters MATCH ?"
      # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
      # In FTS4 it's also a token, so we can just remove it without affecting results
      stm.bind_param 1, query.sub("-", " ")
      rs = stm.execute
      rs.each do |row|
        db_results.push(href: row[0], basecfi: row[1], title: row[2])
      end
      stm.close
      db_results
    end

    def find_by_cfi(cfi)
      stm = @db.prepare "select chapter_id, chapter_href, title, text from chapters where basecfi = ?"
      stm.bind_param 1, cfi
      rs = stm.execute
      row = rs.first
      stm.close
      { id: row[0], href: row[1], basecfi: cfi, title: row[2], doc: row[3] }
    end

    def fetch_chapters
      stm = @db.prepare("select chapter_id, chapter_href, title, basecfi from chapters")
      rs = stm.execute
      results = []
      rs.each do |row|
        results << { id: row[0], href: row[1], title: row[2], basecfi: row[3] }
      end
      stm.close
      results
    end

    private

      def initialize(epub_publication, db)
        @epub_publication = epub_publication
        @db = db
      end
  end
end
