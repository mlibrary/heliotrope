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
      db = SQLite3::Database.new(@db_file)
      db.execute "CREATE VIRTUAL TABLE chapters USING FTS4(chapter_id, chapter_href, basecfi, text)"
      db.close
    end

    def load_chapters
      db = SQLite3::Database.new(@db_file)
      @epub_publication.chapters_from_file.each do |c|
        text = c.doc.search('//text()').map(&:text).delete_if { |x| x !~ /\w/ }
        db.execute "INSERT INTO chapters VALUES (?, ?, ?, ?)", [c.id, c.href, c.basecfi, text.join(" ")]
      end
      db.close
    end

    def search_chapters(query)
      db_results = []
      db = SQLite3::Database.new(@db_file)
      # In sqlite a - (hyphen) acts as NOT which we pretty much never want.
      # In FTS4 it's also a token, so we can just remove it without affecting results
      db.execute("SELECT chapter_href, basecfi from chapters where chapters MATCH ?", [query.sub("-", " ")]) do |row|
        db_results.push(href: row[0], basecfi: row[1])
      end
      db.close
      db_results
    end

    def find_by_cfi(cfi)
      db = SQLite3::Database.new(@db_file)
      row = db.execute("select chapter_id, chapter_href, text from chapters where basecfi = ?", [cfi]).first
      db.close
      { id: row[0], href: row[1], basecfi: cfi, doc: row[2] }
    end

    def fetch_chapters
      results = []
      db = SQLite3::Database.new(@db_file)
      db.execute("select chapter_id, chapter_href, basecfi from chapters") do |row|
        results << { id: row[0], href: row[1], basecfi: row[2] }
      end
      db.close
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
