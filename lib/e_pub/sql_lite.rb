# frozen_string_literal: true

require 'sqlite3'

module EPub
  class SqlLite
    private_class_method :new
    attr_accessor :epub_publication, :db_file

    def self.from_directory(root_path)
      return null_object unless File.exist? root_path
      from_publication(EPub::Publication.from_directory(root_path))
    end

    def self.from_publication(epub_publication)
      db_file = File.join(epub_publication.root_path, "#{epub_publication.id}.db")
      new(epub_publication, db_file)
    end

    def self.null_object
      SqlLiteNullObject.send(:new)
    end

    def create_table
      SQLite3::Database.new @db_file do |db|
        db.execute "CREATE VIRTUAL TABLE chapters USING FTS4(chapter_id, chapter_href, title, basecfi, text)"
      end
    end

    def load_chapters
      SQLite3::Database.new @db_file do |db|
        @epub_publication.chapters_from_file.each do |c|
          text = c.doc.search('//text()').map(&:text).delete_if { |x| x !~ /\w/ }
          db.execute "INSERT INTO chapters VALUES (?, ?, ?, ?, ?)", c.id, c.href, c.title, c.basecfi, text.join(" ")
        end
      end
    end

    def search_chapters(query)
      db_results = []
      SQLite3::Database.new @db_file do |db|
        stm = db.prepare "SELECT chapter_href, basecfi, title from chapters where chapters MATCH ?"
        # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
        # In FTS4 it's also a token, so we can just remove it without affecting results
        stm.bind_param 1, query.sub("-", " ")
        rs = stm.execute
        rs.each do |row|
          db_results.push(href: row[0], basecfi: row[1], title: row[2])
        end
        stm.close
      end
      db_results
    end

    def find_by_cfi(cfi)
      result = {}
      SQLite3::Database.new @db_file do |db|
        stm = db.prepare "select chapter_id, chapter_href, title, text from chapters where basecfi = ?"
        stm.bind_param 1, cfi
        rs = stm.execute
        row = rs.first
        stm.close
        result = { id: row[0], href: row[1], basecfi: cfi, title: row[2], doc: row[3] }
      end
      result
    end

    def fetch_chapters
      results = []
      SQLite3::Database.new @db_file do |db|
        stm = db.prepare("select chapter_id, chapter_href, title, basecfi from chapters")
        rs = stm.execute
        rs.each do |row|
          results << { id: row[0], href: row[1], title: row[2], basecfi: row[3] }
        end
        stm.close
      end
      results
    end

    private

      def initialize(epub_publication, db_file)
        @epub_publication = epub_publication
        @db_file = db_file
      end
  end

  class SqlLiteNullObject < SqlLite
    private_class_method :new
    attr_accessor :epub_publication, :db_file

    def create_table; end

    def load_chapters; end

    def search_chapters(_query)
      []
    end

    def find_by_cfi(_cfi)
      {}
    end

    def fetch_chapters
      []
    end

    private

      def initialize
        @epub_publication = EPub::PublicationNullObject.send(:new)
        @db_file = nil
      end
  end
end
